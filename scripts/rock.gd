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
	match zone:
		1:
			fall_speed = fall_speed_zone1
			horizontal_speed = horizontal_speed_zone1
		2:
			fall_speed = fall_speed_zone2
			horizontal_speed = horizontal_speed_zone2
		3:
			fall_speed = fall_speed_zone3
			horizontal_speed = horizontal_speed_zone3

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

		var main = get_tree().root.get_node("Level")
		if main:
			var sound_player = main.get_node("CollisionSoundPlayer")
			if sound_player:
				sound_player.play()
			else:
				printerr("CollisionSoundPlayer node not found in main scene!")

			# Step 1: Stick the rock to the bucket at the collision point
			var world_pos = global_position  # store current position
			get_parent().remove_child(self)
			body.add_child(self)
			global_position = world_pos  # keep exact collision position

			# Step 2: Stop movement
			set_process(false)

			# Step 3: Trigger Game Over
			main._on_player_hit()

			# Step 4: Remove rock when GameOverPanel appears
			main.game_over_panel.connect("visible_changed", Callable(self, "_on_game_over_panel_visible"))

		else:
			printerr("Main game controller not found!")

func _on_game_over_panel_visible():
	if get_parent().has_node("GameOverPanel") and get_parent().get_node("GameOverPanel").visible:
		queue_free()
