extends Area2D

@export var fall_speed: float = 100
@export var horizontal_speed: float = 50
var horizontal_direction: int = 1
const MARGIN: int = 24  # Margin from screen edges

func _ready():
	var rng := RandomNumberGenerator.new()
	var screen_width = get_viewport().get_visible_rect().size.x
	var random_x = rng.randi_range(MARGIN, screen_width - MARGIN)
	var random_y = rng.randi_range(-150, -50)
	self.position = Vector2(random_x, random_y)
	horizontal_direction = 1 if randf() > 0.5 else -1
	add_to_group("stone")

func _process(delta: float) -> void:
	# Move the rock
	self.position.y += fall_speed * delta
	self.position.x += horizontal_speed * horizontal_direction * delta

	var screen_width = get_viewport_rect().size.x

	# Bounce back from screen edges using margins
	if position.x < MARGIN or position.x > (screen_width - MARGIN):
		horizontal_direction *= -1

	# Remove the rock if it goes below the screen
	if position.y > get_viewport_rect().size.y:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("bucket"):
		print("Rock collided with bucket! Game over!")
		# Handle game over logic here, if needed
