extends Area2D

# Custom velocity property for the jewel
var velocity = Vector2.ZERO

# Screen boundaries
var screen_left_boundary = 50
var screen_right_boundary = 0

func _ready():
	screen_right_boundary = get_viewport_rect().size.x - 50

func _process(delta):
	# Update position based on velocity
	position += velocity * delta

	# Check if the jewel is off-screen (vertically)
	if position.y > get_viewport().size.y + 50:
		queue_free()  # Remove jewel from the scene when it falls off-screen

	# Horizontal boundary check (left and right walls)
	if position.x <= screen_left_boundary or position.x >= screen_right_boundary:
		velocity.x = -velocity.x  # Reverse the horizontal movement

	# Clamp position to screen bounds
	position.x = clamp(position.x, screen_left_boundary, screen_right_boundary)

func _on_Jewel_body_entered(body):
	if body.name == "Bucket":  # Assuming the bucket node is named "Bucket"
		queue_free()  # Remove the jewel when collected by the bucket
