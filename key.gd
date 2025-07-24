extends CharacterBody2D

@export var fall_speed: float = 100
@export var sway_amplitude: float = 180  # How far left/right it sways
@export var sway_speed: float = 2.0      # How fast it sways
@export var vertical_offset: float = -100  # How far from the top to start

var time_passed: float = 0.0
var center_x: float = 0.0

func _ready() -> void:
	var screen_size = get_viewport_rect().size
	center_x = screen_size.x / 3
	position = Vector2(center_x, vertical_offset)  # Top center with vertical offset
	add_to_group("key")

func _physics_process(delta: float) -> void:
	time_passed += delta
	
	# Swaying left and right using sine wave
	var sway = sin(time_passed * sway_speed) * sway_amplitude
	position.x = center_x + sway

	# Constant falling
	velocity = Vector2(0, fall_speed)
	move_and_slide()

	# Remove if off-screen
	if position.y > get_viewport_rect().size.y:
		queue_free()
