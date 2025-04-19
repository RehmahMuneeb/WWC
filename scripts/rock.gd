extends Area2D

@export var fall_speed: float = 100
@export var horizontal_speed: float = 50
var horizontal_direction: int = 1

func _ready():
	var rng := RandomNumberGenerator.new()
	var width = get_viewport().get_visible_rect().size.x
	var random_x = rng.randi_range(0, width)
	var random_y = rng.randi_range(-150, -50)
	self.position = Vector2(random_x, random_y)
	horizontal_direction = 1 if randf() > 0.5 else -1
	add_to_group("stone")

func _process(delta: float) -> void:
	self.position.y += fall_speed * delta
	self.position.x += horizontal_speed * horizontal_direction * delta
	if position.x < 0 or position.x > get_viewport_rect().size.x:
		horizontal_direction *= -1
	if position.y > get_viewport_rect().size.y:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	print("Rock collided with: ", body.name)
	if body.is_in_group("bucket"):
		print("Rock collided with bucket! Game over!")
		#get_tree().change_scene_to_file("res://scenes/main.tscn") 
