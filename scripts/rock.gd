extends Area2D

@export var fall_speed_zone1: float = 200.0
@export var horizontal_speed_zone1: float = 100.0

@export var fall_speed_zone2: float = 150.0
@export var horizontal_speed_zone2: float = 60.0

@export var fall_speed_zone3: float = 120.0
@export var horizontal_speed_zone3: float = 50.0

var fall_speed: float = 100.0
var horizontal_speed: float = 50.0
var horizontal_direction: int = 1
var zone = 1

const MARGIN: int = 24

func set_zone(value: int) -> void:
	zone = value

func _ready():
	var rng := RandomNumberGenerator.new()
	rng.randomize()

	var screen_width = get_viewport().get_visible_rect().size.x
	var random_x = rng.randi_range(MARGIN, screen_width - MARGIN)
	var random_y = rng.randi_range(-150, -50)

	position = Vector2(random_x, random_y)
	horizontal_direction = 1 if rng.randf() > 0.5 else -1

	add_to_group("stone")

func _process(delta: float) -> void:
	position.y += fall_speed * delta
	position.x += horizontal_speed * horizontal_direction * delta

	var screen_width = get_viewport_rect().size.x

	if position.x < MARGIN or position.x > (screen_width - MARGIN):
		horizontal_direction *= -1

	if position.y > get_viewport_rect().size.y:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("bucket"):
		print("Rock collided with bucket! Game over!")
		call_deferred("_change_to_back_menu")

func _change_to_back_menu():
	get_tree().change_scene_to_file("res://back_menu.tscn")
