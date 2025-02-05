extends CharacterBody2D

# Speed at which the jewel falls
@export var fall_speed: float = 100

# Speed at which the jewel moves horizontally
@export var horizontal_speed: float = 50

# Direction of horizontal movement (1 for right, -1 for left)
var horizontal_direction: int = 1

# Array to hold jewel textures
@export var jewel_textures: Array[Texture2D] = []

func _ready() -> void:
	# Randomly assign a jewel texture
	if jewel_textures.size() > 0:
		$Sprite2D.texture = jewel_textures[randi() % jewel_textures.size()]

	# Randomize the initial horizontal direction
	horizontal_direction = 1 if randf() > 0.5 else -1

	# Add the jewel to the "jewel" group
	add_to_group("jewel")

func _process(delta: float) -> void:
	# Move the jewel downward
	velocity.y = fall_speed

	# Move the jewel horizontally
	velocity.x = horizontal_speed * horizontal_direction

	move_and_slide()

	# Remove the jewel if it goes off-screen
	if position.y > get_viewport_rect().size.y:
		queue_free()

	# Bounce the jewel off the screen boundaries
	if position.x < 0 or position.x > get_viewport_rect().size.x:
		horizontal_direction *= -1  # Reverse horizontal direction
