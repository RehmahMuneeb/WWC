extends Control

# Configuration
const MAX_DEPTH := 40000
const TICK_SPACING := 1000
const MINOR_TICK_SPACING := 100
const VIEWPORT_HEIGHT := 850
const DEPTH_SCALE := 0.1
const SCROLL_SPEED := 500.0

# Colors
const COVERED_LINE_COLOR := Color.GOLD
const UNCOVERED_LINE_COLOR := Color.FLORAL_WHITE
const MAJOR_TICK_COVERED_COLOR := Color.TOMATO
const MAJOR_TICK_DEFAULT_COLOR := Color.TOMATO
const LABEL_COVERED_COLOR := Color.GOLD
const LABEL_DEFAULT_COLOR := Color.AQUAMARINE

# Nodes
@onready var depth_line := $ScrollContainer/DepthMap/DepthLine
@onready var covered_line := $ScrollContainer/DepthMap/CoveredLine
@onready var major_ticks := $ScrollContainer/DepthMap/MajorTicks
@onready var minor_ticks := $ScrollContainer/DepthMap/MinorTicks
@onready var player_icon := $PlayerIcon
@onready var depth_label := $DepthLabel
@onready var highscore_icon := $ScrollContainer/DepthMap/HighScoreIcon
@onready var highscore_label := $ScrollContainer/DepthMap/HighScoreLabel

# Score tracking
var current_score: float = 0.0
var target_score: float = 0.0
var scrolling: bool = false
var highscore_broken := false
var blink_tween: Tween = null

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(true)
	_load_highscore()
	_generate_depth_line()
	_generate_covered_line()
	_generate_ticks()
	update_display()

func _process(delta: float) -> void:
	if scrolling:
		if abs(current_score - target_score) < 1:
			current_score = target_score
			scrolling = false
			_stop_blinking()
		else:
			var direction = sign(target_score - current_score)
			current_score += direction * SCROLL_SPEED * delta
			current_score = clamp(current_score, 0, MAX_DEPTH)
		update_display()

func set_current_score(score: int) -> void:
	current_score = 0
	target_score = clamp(score, 0, MAX_DEPTH)
	scrolling = true
	highscore_broken = false

func update_display() -> void:
	var center_y: float = VIEWPORT_HEIGHT / 2
	var scroll_offset: float = (MAX_DEPTH * DEPTH_SCALE) - (current_score * DEPTH_SCALE) - center_y

	# Scroll all elements
	depth_line.position.y = -scroll_offset
	covered_line.position.y = -scroll_offset
	major_ticks.position.y = -scroll_offset
	minor_ticks.position.y = -scroll_offset

	# Update covered line
	covered_line.clear_points()
	covered_line.default_color = COVERED_LINE_COLOR
	covered_line.width = depth_line.width
	var start_y = (MAX_DEPTH - current_score) * DEPTH_SCALE
	covered_line.add_point(Vector2(0, start_y))
	covered_line.add_point(Vector2(0, MAX_DEPTH * DEPTH_SCALE))

	# Update tick and label colors
	for child in major_ticks.get_children():
		if child is Line2D:
			var tick_depth = MAX_DEPTH - (child.get_point_position(0).y / DEPTH_SCALE)
			child.default_color = MAJOR_TICK_COVERED_COLOR if tick_depth <= current_score else MAJOR_TICK_DEFAULT_COLOR
		elif child is Label:
			var label_depth = MAX_DEPTH - (child.position.y + 22) / DEPTH_SCALE
			var new_settings = LabelSettings.new()
			new_settings.font_size = 28
			new_settings.font_color = LABEL_COVERED_COLOR if label_depth <= current_score else LABEL_DEFAULT_COLOR
			child.label_settings = new_settings

	# Update player position and label
	var player_y := (MAX_DEPTH - current_score) * DEPTH_SCALE
	player_icon.position = Vector2(242, player_y - scroll_offset)
	depth_label.text = "YOU SCORE\n%d M" % int(current_score)
	depth_label.position = Vector2(95, center_y - 25)

	# High score logic
# High score logic
	if current_score > Global.highscore:
		if not highscore_broken:
			highscore_broken = true
			Global.highscore = int(current_score)
			_save_highscore()

# Start blinking only if score is scrolling
	if Global.highscore > 0 and scrolling:
		if not _is_blinking():
			_start_blinking()
	elif _is_blinking():
		_stop_blinking()



	# Position highscore icon and label
	if Global.highscore > 0:
		var highscore_y = (MAX_DEPTH - Global.highscore) * DEPTH_SCALE
		highscore_icon.position = Vector2(156, highscore_y - scroll_offset)
		highscore_icon.visible = true

		highscore_label.text = "HIGHSCORE\n%d M" % Global.highscore
		highscore_label.position = Vector2(12, highscore_y - scroll_offset - 22)
		highscore_label.visible = true
	else:
		highscore_icon.visible = false
		highscore_label.visible = false

# Tween logic for blinking
func _start_blinking():
	_stop_blinking()
	highscore_icon.modulate.a = 1.0
	blink_tween = create_tween()
	blink_tween.set_loops()
	blink_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	blink_tween.tween_property(highscore_icon, "modulate:a", 0.2, 0.4)
	blink_tween.tween_property(highscore_icon, "modulate:a", 1.0, 0.4)

func _stop_blinking():
	if blink_tween:
		blink_tween.kill()
		blink_tween = null
		highscore_icon.modulate.a = 1.0

func _is_blinking() -> bool:
	return blink_tween != null

# Depth line generation
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
	covered_line.add_point(Vector2(0, MAX_DEPTH * DEPTH_SCALE))
	covered_line.add_point(Vector2(0, MAX_DEPTH * DEPTH_SCALE))

func _generate_ticks() -> void:
	for child in major_ticks.get_children():
		child.queue_free()
	for child in minor_ticks.get_children():
		child.queue_free()

	for depth in range(0, MAX_DEPTH + 1, TICK_SPACING):
		var y_pos = (MAX_DEPTH - depth) * DEPTH_SCALE
		var tick := Line2D.new()
		tick.width = 6
		tick.default_color = MAJOR_TICK_DEFAULT_COLOR
		tick.add_point(Vector2(-18, y_pos))
		tick.add_point(Vector2(18, y_pos))
		major_ticks.add_child(tick)

		var label := Label.new()
		label.text = "→ %d m" % depth
		label.position = Vector2(30, y_pos - 23)
		var label_settings := LabelSettings.new()
		label_settings.font_size = 28
		label_settings.font_color = LABEL_DEFAULT_COLOR
		label.label_settings = label_settings
		major_ticks.add_child(label)

	for depth in range(0, MAX_DEPTH + 1, MINOR_TICK_SPACING):
		if depth % TICK_SPACING == 0:
			continue
		var y_pos = (MAX_DEPTH - depth) * DEPTH_SCALE
		var tick := Line2D.new()
		tick.width = 2
		tick.default_color = Color.GRAY
		tick.add_point(Vector2(-10, y_pos))
		tick.add_point(Vector2(10, y_pos))
		minor_ticks.add_child(tick)

# Highscore persistence
func _save_highscore():
	var file = FileAccess.open("user://highscore.save", FileAccess.WRITE)
	if file:
		file.store_32(Global.highscore)

func _load_highscore():
	if FileAccess.file_exists("user://highscore.save"):
		var file = FileAccess.open("user://highscore.save", FileAccess.READ)
		if file:
			Global.highscore = file.get_32()
	else:
		Global.highscore = 0
