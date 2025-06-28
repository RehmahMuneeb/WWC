extends CharacterBody2D

# Speed at which the jewel falls
@export var fall_speed: float = 100

# Base horizontal speed (will be overridden with random on spawn)
@export var horizontal_speed: float = 300

# Minimum and maximum horizontal speed range
@export var min_horizontal_speed: float = 100
@export var max_horizontal_speed: float = 300

# Direction of horizontal movement (1 for right, -1 for left)
var horizontal_direction: int = 1

# Array to hold jewel textures
@export var jewel_textures: Array[Texture2D] = []

# Gameplay screen boundaries (adjust these to match your gameplay area)
@export var gameplay_left_boundary: float = 0
@export var gameplay_right_boundary: float = 500  # Example: Set this to your gameplay screen width

func _ready() -> void:
	# Randomly assign a jewel texture
	if jewel_textures.size() > 0:
		$Sprite2D.texture = jewel_textures[randi() % jewel_textures.size()]

	# Randomize the initial horizontal direction
	horizontal_direction = 1 if randf() > 0.5 else -1

	# Randomize the horizontal speed within the specified range
	horizontal_speed = randf_range(min_horizontal_speed, max_horizontal_speed)

	if Global.jewel_textures.is_empty():
		Global.jewel_textures = jewel_textures.duplicate()
	# Add the jewel to the "jewel" group
	add_to_group("jewel")

func _process(delta: float) -> void:
	# Move the jewel downward
	velocity.y = fall_speed

	# Move the jewel horizontally
	velocity.x = horizontal_speed * horizontal_direction

	move_and_slide()

	# Remove the jewel if it goes off-screen vertically
	if position.y > get_viewport_rect().size.y:
		queue_free()

	# Get the width of the jewel's texture
	var jewel_width: float = $Sprite2D.texture.get_width() if $Sprite2D.texture else 0

	# Bounce the jewel off the gameplay screen boundaries
	if position.x < gameplay_left_boundary:
		horizontal_direction = 1  # Move right
	elif position.x + jewel_width > gameplay_right_boundary:
		horizontal_direction = -1  # Move left
