extends Control

### CONFIGURATION ###
const MAX_DEPTH := 40000
const TICK_SPACING := 1000
const MINOR_TICK_SPACING := 250
const VIEWPORT_HEIGHT := 850
const DEPTH_SCALE := 0.08
const MILESTONE_SPACING := 11000
const MILESTONE_PEEK_DURATION := 0.1
const HIGHSCORE_PEEK_DURATION := 2.0
const MILESTONE_ICON_SPACING := 16
const MARGIN_THRESHOLD := 10.0
const MILESTONE_DELAY := 2.0
const MILESTONE_PULSE_SPEED := 1.5  # Speed of the pulsing animation

@export var scroll_speed := 1.8
@export var milestone_scroll_speed := 5
### COLORS ###
const COVERED_LINE_COLOR := Color.GOLD
const UNCOVERED_LINE_COLOR := Color.FLORAL_WHITE
const MAJOR_TICK_COVERED_COLOR := Color.TOMATO
const MAJOR_TICK_DEFAULT_COLOR := Color.TOMATO
const LABEL_COVERED_COLOR := Color.GOLD
const LABEL_DEFAULT_COLOR := Color.AQUAMARINE

### NODES ###
@onready var depth_line := $ScrollContainer/DepthMap/DepthLine
@onready var covered_line := $ScrollContainer/DepthMap/CoveredLine
@onready var major_ticks := $ScrollContainer/DepthMap/MajorTicks
@onready var minor_ticks := $ScrollContainer/DepthMap/MinorTicks
@onready var player_icon := $PlayerIcon
@onready var depth_label := $DepthLabel
@onready var highscore_icon := $ScrollContainer/DepthMap/HighScoreIcon
@onready var highscore_label := $ScrollContainer/DepthMap/HighScoreLabel
@onready var milestone_icon := $ScrollContainer/DepthMap/MileStone

### STATE VARIABLES ###
var milestone_icons: Array = []
var current_milestone_number: int = 0
var current_score: float = 0.0
var target_score: float = 0.0
var scrolling: bool = false
var highscore_broken: bool = false
var original_score: float = 0.0
var next_milestone: int = 0
var covered_line_drawn: bool = false
var is_milestone_sequence: bool = false
var pending_highscore: int = -1
var milestone_tweens: Array = []

var milestone_pulse_active := false

var _label_settings_default: LabelSettings
var _label_settings_covered: LabelSettings

var scroll_tween: Tween
var ui_tween: Tween

var _tick_limit: int = 20000

func _ready() -> void:
	if OS.has_feature("mobile"):
		get_viewport().msaa_2d = Viewport.MSAA_2X
		get_viewport().canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_LINEAR

	_label_settings_default = LabelSettings.new()
	_label_settings_default.font_size = 24
	_label_settings_default.font_color = LABEL_DEFAULT_COLOR

	_label_settings_covered = LabelSettings.new()
	_label_settings_covered.font_size = 24
	_label_settings_covered.font_color = LABEL_COVERED_COLOR

	_generate_depth_line()
	_generate_covered_line()
	_regenerate_ticks(_tick_limit)

	for i in range(2):
		var new_icon = milestone_icon.duplicate()
		$ScrollContainer/DepthMap.add_child(new_icon)
		new_icon.name = "MileStone%d" % (i + 2)
		milestone_icons.append(new_icon)
	milestone_icons = [milestone_icon] + milestone_icons

	update_display()
	next_milestone = _get_next_milestone(0)

	# Start milestone pulse once here if milestone icons are visible initially
	if milestone_icons.size() > 0:
		_start_milestone_pulse()

func _start_milestone_pulse() -> void:
	if milestone_pulse_active:
		return  # Already running, skip
	
	# Reset scales before starting tweens
	for icon in milestone_icons:
		if icon.visible:
			icon.scale = Vector2(1.0, 1.0)
	
	# Clear old tweens
	for tween in milestone_tweens:
		tween.kill()
	milestone_tweens.clear()
	
	# Create continuous pulse animation for each visible milestone icon
	for icon in milestone_icons:
		if icon.visible:
			var tween = create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			tween.tween_property(icon, "scale", Vector2(0.4, 0.4), MILESTONE_PULSE_SPEED / 2)
			tween.tween_property(icon, "scale", Vector2(0.3, 0.3), MILESTONE_PULSE_SPEED / 2)
			milestone_tweens.append(tween)
	
	milestone_pulse_active = true

func _stop_milestone_pulse() -> void:
	for tween in milestone_tweens:
		tween.kill()
	milestone_tweens.clear()
	for icon in milestone_icons:
		if icon.visible:
			icon.scale = Vector2(1.0, 1.0)
	milestone_pulse_active = false

func set_current_score(score: int) -> void:
	if scrolling:
		return
	target_score = clamp(score, 0, MAX_DEPTH)
	_start_scroll_to_target()

func _start_scroll_to_target() -> void:
	if scroll_tween:
		scroll_tween.kill()
	scrolling = true
	scroll_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	scroll_tween.tween_method(_update_scroll_position, current_score, target_score, scroll_speed)
	scroll_tween.tween_callback(_on_target_reached)

func _update_scroll_position(value: float) -> void:
	current_score = value
	_ensure_tick_limit_for_score(current_score)

	if not covered_line_drawn:
		_update_covered_line(current_score)

	if not is_milestone_sequence and current_score > Global.highscore and not highscore_broken:
		pending_highscore = int(current_score)
		_handle_highscore_pass()

	update_display()

func _update_covered_line(score_val: float) -> void:
	covered_line.default_color = COVERED_LINE_COLOR
	covered_line.width = depth_line.width
	covered_line.clear_points()
	var start_y = (MAX_DEPTH - score_val) * DEPTH_SCALE
	covered_line.add_point(Vector2(0, start_y))
	covered_line.add_point(Vector2(0, MAX_DEPTH * DEPTH_SCALE))

func _on_target_reached() -> void:
	scrolling = false
	covered_line_drawn = true
	
	if pending_highscore > Global.highscore:
		Global.highscore = pending_highscore
		pending_highscore = -1
	
	await get_tree().create_timer(MILESTONE_DELAY).timeout
	_start_milestone_sequence()

func _start_milestone_sequence() -> void:
	is_milestone_sequence = true
	original_score = current_score
	next_milestone = _get_next_milestone(current_score)
	if current_score >= next_milestone:
		next_milestone = _get_next_milestone(next_milestone + 1)
	if next_milestone > MAX_DEPTH:
		is_milestone_sequence = false
		return

	# Fade out UI
	ui_tween = create_tween().set_parallel(true)
	ui_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	ui_tween.tween_property(player_icon, "modulate:a", 0.0, 0.3)
	ui_tween.parallel().tween_property(depth_label, "modulate:a", 0.0, 0.3)
	await ui_tween.finished
	
	player_icon.visible = false
	depth_label.visible = false

	# Scroll to milestone
	scroll_tween = create_tween().set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	scroll_tween.tween_method(_update_scroll_position, current_score, next_milestone, milestone_scroll_speed)
	await scroll_tween.finished

	# Start continuous pulsing animation
	_start_milestone_pulse()
	
	# Wait milestone peek duration while pulsing
	await get_tree().create_timer(MILESTONE_PEEK_DURATION).timeout

	# Scroll back while still pulsing
	scroll_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	scroll_tween.tween_method(_update_scroll_position, current_score, original_score, milestone_scroll_speed)
	await scroll_tween.finished

	# Stop pulsing animation after scroll back finishes
	_stop_milestone_pulse()

	# Fade in UI
	player_icon.visible = true
	depth_label.visible = true
	ui_tween = create_tween().set_parallel(true)
	ui_tween.tween_property(player_icon, "modulate:a", 1.0, 0.3)
	ui_tween.parallel().tween_property(depth_label, "modulate:a", 1.0, 0.3)
	await ui_tween.finished

	is_milestone_sequence = false
	next_milestone = _get_next_milestone(current_score)

func _handle_highscore_pass() -> void:
	highscore_broken = true
	var hs_tween = create_tween()
	hs_tween.tween_property(highscore_icon, "scale", Vector2(1.5, 1.5), 0.3)
	hs_tween.tween_interval(HIGHSCORE_PEEK_DURATION)
	hs_tween.tween_property(highscore_icon, "scale", Vector2(1.0, 1.0), 0.3)
	highscore_broken = false

func _get_next_milestone(score: float) -> int:
	return ceil((score + 1) / MILESTONE_SPACING) * MILESTONE_SPACING

func update_display() -> void:
	var center_y: float = VIEWPORT_HEIGHT / 2
	var scroll_offset: float = (MAX_DEPTH * DEPTH_SCALE) - (current_score * DEPTH_SCALE) - center_y

	depth_line.position.y = -scroll_offset
	covered_line.position.y = -scroll_offset
	major_ticks.position.y = -scroll_offset
	minor_ticks.position.y = -scroll_offset

	if not is_milestone_sequence:
		for child in major_ticks.get_children():
			if child is Line2D:
				var tick_depth: float = MAX_DEPTH - (child.get_point_position(0).y / DEPTH_SCALE)
				child.default_color = MAJOR_TICK_COVERED_COLOR if tick_depth <= current_score else MAJOR_TICK_DEFAULT_COLOR
			elif child is Label:
				var label_depth: float = MAX_DEPTH - (child.position.y + 22) / DEPTH_SCALE
				child.label_settings = _label_settings_covered if label_depth <= current_score else _label_settings_default
	else:
		for child in major_ticks.get_children():
			if child is Label:
				child.label_settings = _label_settings_default

	var player_y := (MAX_DEPTH - current_score) * DEPTH_SCALE
	player_icon.position = Vector2(242, player_y - scroll_offset)
	depth_label.text = "YOU\n%d M" % int(current_score)
	depth_label.position = Vector2(95, center_y - 25)

	if Global.highscore > 0:
		var highscore_y: float = (MAX_DEPTH - Global.highscore) * DEPTH_SCALE
		highscore_icon.position = Vector2(156, highscore_y - scroll_offset)
		
		if pending_highscore > 0 or current_score >= Global.highscore:
			highscore_label.text = "NEW\nHIGH SCORE\n%d M" % Global.highscore
		else:
			highscore_label.text = "HIGH SCORE\n%d M" % Global.highscore
			
		highscore_label.position = Vector2(12, highscore_y - scroll_offset - 22)
		highscore_label.visible = true
		highscore_icon.visible = true
	else:
		highscore_label.visible = false
		highscore_icon.visible = false

	if MILESTONE_SPACING > 0:
		var next_milestone_depth: int = _get_next_milestone(current_score)
		current_milestone_number = next_milestone_depth / MILESTONE_SPACING if next_milestone_depth > 0 else 0
		for icon in milestone_icons:
			icon.visible = false
		if next_milestone_depth <= MAX_DEPTH:
			var milestone_y: float = (MAX_DEPTH - next_milestone_depth) * DEPTH_SCALE - scroll_offset
			var icon_count: int = min(current_milestone_number, 3)
			for i in range(icon_count):
				if i < milestone_icons.size():
					var x_offset: float = (i - (icon_count - 1) / 2.0) * MILESTONE_ICON_SPACING
					milestone_icons[i].position = Vector2(156 + x_offset, milestone_y)
					milestone_icons[i].visible = true
	
	# Start pulsing animation when milestones are visible (outside of milestone sequence)
	if not is_milestone_sequence:
		_start_milestone_pulse()

func _generate_depth_line() -> void:
	depth_line.clear_points()
	depth_line.default_color = UNCOVERED_LINE_COLOR
	depth_line.width = 44
	depth_line.add_point(Vector2(0, 0))
	depth_line.add_point(Vector2(0, MAX_DEPTH * DEPTH_SCALE))

func _generate_covered_line() -> void:
	covered_line.clear_points()
	covered_line.default_color = COVERED_LINE_COLOR
	covered_line.width = depth_line.width
	covered_line.add_point(Vector2(0, 0))
	covered_line.add_point(Vector2(0, 0))

func _regenerate_ticks(upto_depth: int) -> void:
	var cap_depth: int = min(upto_depth, MAX_DEPTH)
	for child in major_ticks.get_children():
		child.queue_free()
	for child in minor_ticks.get_children():
		child.queue_free()
	for depth in range(0, cap_depth + 1, TICK_SPACING):
		var y_pos: float = (MAX_DEPTH - depth) * DEPTH_SCALE
		var tick := Line2D.new()
		tick.width = 6
		tick.default_color = MAJOR_TICK_DEFAULT_COLOR
		tick.add_point(Vector2(-18, 0))
		tick.add_point(Vector2(18, 0))
		tick.position = Vector2(0, y_pos)
		major_ticks.add_child(tick)
		var label := Label.new()
		label.text = "→ %d m" % depth
		label.position = Vector2(30, y_pos - 23)
		label.label_settings = _label_settings_default
		major_ticks.add_child(label)
	for depth in range(0, cap_depth + 1, MINOR_TICK_SPACING):
		if depth % TICK_SPACING == 0:
			continue
		var y_pos: float = (MAX_DEPTH - depth) * DEPTH_SCALE
		var tick := Line2D.new()
		tick.width = 2
		tick.default_color = Color.GRAY
		tick.add_point(Vector2(-10, 0))
		tick.add_point(Vector2(10, 0))
		tick.position = Vector2(0, y_pos)
		minor_ticks.add_child(tick)

func _ensure_tick_limit_for_score(score_val: float) -> void:
	var old_limit: int = _tick_limit
	if score_val > 20000:
		_tick_limit = 40000
	elif score_val > 10000:
		_tick_limit = 30000
	else:
		_tick_limit = 20000
	if _tick_limit != old_limit:
		_regenerate_ticks(_tick_limit)

func finalize_score():
	if current_score > Global.highscore:
		Global.highscore = int(current_score)

func _exit_tree() -> void:
	if scroll_tween:
		scroll_tween.kill()
	for tween in milestone_tweens:
		tween.kill()
	if ui_tween:
		ui_tween.kill()
