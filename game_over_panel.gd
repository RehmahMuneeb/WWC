extends Control

# Configuration
const MAX_DEPTH := 40000
const TICK_SPACING := 1000
const MINOR_TICK_SPACING := 100
const VIEWPORT_HEIGHT := 800
const DEPTH_SCALE := 0.1
const SCROLL_SPEED := 500.0  # meters per second

# Colors
const COVERED_LINE_COLOR := Color.GOLD
const UNCOVERED_LINE_COLOR := Color.TURQUOISE
const MAJOR_TICK_COVERED_COLOR := Color.GOLD
const MAJOR_TICK_DEFAULT_COLOR := Color.TEAL
const LABEL_COVERED_COLOR := Color.GOLD
const LABEL_DEFAULT_COLOR := Color.TURQUOISE

# Nodes
@onready var depth_line := $ScrollContainer/DepthMap/DepthLine
@onready var covered_line := $ScrollContainer/DepthMap/CoveredLine
@onready var major_ticks := $ScrollContainer/DepthMap/MajorTicks
@onready var minor_ticks := $ScrollContainer/DepthMap/MinorTicks
@onready var player_icon := $PlayerIcon
@onready var depth_label := $DepthLabel
@onready var highscore_icon := $HighScoreIcon

# Score tracking
var current_score: float = 0.0
var target_score: float = 0.0
var scrolling: bool = false

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(true)
	_generate_depth_line()
	_generate_covered_line()
	_generate_ticks()
	update_display()

func _process(delta: float) -> void:
	if scrolling:
		if abs(current_score - target_score) < 1:
			current_score = target_score
			scrolling = false
		else:
			var direction = sign(target_score - current_score)
			current_score += direction * SCROLL_SPEED * delta
			current_score = clamp(current_score, 0, MAX_DEPTH)
		update_display()

func set_current_score(score: int) -> void:
	current_score = 0  # Start from top
	target_score = clamp(score, 0, MAX_DEPTH)
	scrolling = true

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
			var label_depth = MAX_DEPTH - (child.position.y + 22) / DEPTH_SCALE  # Adjust for label position
			# Create new LabelSettings to modify color
			var new_settings = LabelSettings.new()
			new_settings.font_size = 28
			new_settings.font_color = LABEL_COVERED_COLOR if label_depth <= current_score else LABEL_DEFAULT_COLOR
			child.label_settings = new_settings

	# Update player position and label
	var player_y := (MAX_DEPTH - current_score) * DEPTH_SCALE
	player_icon.position = Vector2(242, player_y - scroll_offset)
	depth_label.text = "YOU SCORE\n%d M" % int(current_score)

	depth_label.position = Vector2(63, center_y - 31)

	# Update highscore
	if Global.highscore > 0:
		var highscore_y = (MAX_DEPTH - Global.highscore) * DEPTH_SCALE
		highscore_icon.position.y = highscore_y - scroll_offset
		highscore_icon.visible = true
	else:
		highscore_icon.visible = false

func _generate_depth_line() -> void:
	depth_line.clear_points()
	depth_line.default_color = UNCOVERED_LINE_COLOR
	depth_line.width = 8
	depth_line.add_point(Vector2(0, 0))
	depth_line.add_point(Vector2(0, MAX_DEPTH * DEPTH_SCALE))

func _generate_covered_line() -> void:
	covered_line.clear_points()
	covered_line.default_color = COVERED_LINE_COLOR
	covered_line.width = depth_line.width
	covered_line.add_point(Vector2(0, MAX_DEPTH * DEPTH_SCALE))
	covered_line.add_point(Vector2(0, MAX_DEPTH * DEPTH_SCALE))

func _generate_ticks() -> void:
	# Clear previous ticks
	for child in major_ticks.get_children():
		child.queue_free()
	for child in minor_ticks.get_children():
		child.queue_free()

	# Major ticks and labels
	for depth in range(0, MAX_DEPTH + 1, TICK_SPACING):
		var y_pos = (MAX_DEPTH - depth) * DEPTH_SCALE

		# Create tick mark
		var tick := Line2D.new()
		tick.width = 6
		tick.default_color = MAJOR_TICK_DEFAULT_COLOR
		tick.add_point(Vector2(-30, y_pos))
		tick.add_point(Vector2(30, y_pos))
		major_ticks.add_child(tick)

		# Create label with unique LabelSettings
		var label := Label.new()
		label.text = "→ %d m" % depth
		label.position = Vector2(30, y_pos - 23)
		
		var label_settings := LabelSettings.new()
		label_settings.font_size = 28
		label_settings.font_color = LABEL_DEFAULT_COLOR
		label.label_settings = label_settings
		
		major_ticks.add_child(label)

	# Minor ticks
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
