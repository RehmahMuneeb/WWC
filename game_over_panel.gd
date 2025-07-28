extends Control

# Configuration
const MAX_DEPTH := 40000
const TICK_SPACING := 1000
const MINOR_TICK_SPACING := 100
const VIEWPORT_HEIGHT := 600
const DEPTH_SCALE := 0.5
const SCROLL_SPEED := 500.0  # meters per second

# Nodes
@onready var depth_line := $ScrollContainer/DepthMap/DepthLine
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
	process_mode = Node.PROCESS_MODE_ALWAYS  # Ensures _process runs during paused state
	set_process(true)
	_generate_depth_line()
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
	print("Scrolling to score:", score)
	current_score = 0  # Start from top, or change to current_score to scroll from last
	target_score = clamp(score, 0, MAX_DEPTH)
	scrolling = true

func update_display() -> void:
	var center_y: float = VIEWPORT_HEIGHT / 2
	player_icon.position = Vector2(200, center_y - 100)
	
	depth_label.text = "%d m" % int(current_score)
	depth_label.position = Vector2(40, center_y - 10)
	
	var scroll_offset: float = (MAX_DEPTH * DEPTH_SCALE) - (current_score * DEPTH_SCALE) - center_y
	
	depth_line.position.y = -scroll_offset
	major_ticks.position.y = -scroll_offset
	minor_ticks.position.y = -scroll_offset
	
	if Global.highscore > 0:
		highscore_icon.position.y = (MAX_DEPTH * DEPTH_SCALE) - (Global.highscore * DEPTH_SCALE) - scroll_offset
		highscore_icon.visible = true
	else:
		highscore_icon.visible = false

func _generate_depth_line() -> void:
	depth_line.clear_points()
	depth_line.default_color = Color.WHITE
	depth_line.width = 2
	depth_line.add_point(Vector2(0, 0))
	depth_line.add_point(Vector2(0, MAX_DEPTH * DEPTH_SCALE))

func _generate_ticks() -> void:
	for child in major_ticks.get_children():
		child.queue_free()
	for child in minor_ticks.get_children():
		child.queue_free()
	
	for depth in range(MAX_DEPTH, -1, -TICK_SPACING):
		var y_pos: float = (MAX_DEPTH - depth) * DEPTH_SCALE
		
		var tick := Line2D.new()
		tick.width = 3
		tick.default_color = Color.CYAN
		tick.add_point(Vector2(-20, y_pos))
		tick.add_point(Vector2(20, y_pos))
		major_ticks.add_child(tick)
		
		var label := Label.new()
		label.text = "%d m" % depth
		label.position = Vector2(30, y_pos - 10)
		major_ticks.add_child(label)
	
	for depth in range(MAX_DEPTH, -1, -MINOR_TICK_SPACING):
		if depth % TICK_SPACING == 0:
			continue
		var y_pos: float = (MAX_DEPTH - depth) * DEPTH_SCALE
		var tick := Line2D.new()
		tick.width = 1
		tick.default_color = Color.GRAY
		tick.add_point(Vector2(-10, y_pos))
		tick.add_point(Vector2(10, y_pos))
		minor_ticks.add_child(tick)
