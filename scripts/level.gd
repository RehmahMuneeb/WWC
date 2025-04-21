extends Node2D

var rock_scene: PackedScene = load("res://scenes/rock.tscn")
var normal_texture = preload("res://assets/rock.png")
var lava2_texture = preload("res://assets/Lavarock88.png") # for 7000–8000m
var lava3_texture = preload("res://assets/rock.png") # for 11000–12000m

var score = 0
var in_danger_zone = false
var reset_zone = false

@onready var rock_timer = $Rocks/RockTimer
@onready var score_label = $UI/Score
@onready var depth_bar = $UI/ProgressBar
@onready var anim_player = $UI/ProgressBar/AnimationPlayer

@export var horizontal_speed: float = 100.0
@export var fall_speed: float = 200.0

@export var horizontal_speed_lava2: float = 60.0   # for 7000–8000m
@export var fall_speed_lava2: float = 150.0

@export var horizontal_speed_lava3: float = 50.0   # for 11000–12000m
@export var fall_speed_lava3: float = 120.0

func _ready():
	score = 0
	depth_bar.min_value = 0
	depth_bar.max_value = 3000
	rock_timer.wait_time = 2.0
	rock_timer.start()

	var fill_stylebox = depth_bar.get("custom_styles/fill")
	if fill_stylebox:
		fill_stylebox.bg_color = Color(1, 0, 0)

func _process(delta):
	score += 1
	score_label.text = str(score) + "m"

	var cycle_pos = score % 12000

	if cycle_pos >= 7000 and cycle_pos < 8000:
		horizontal_speed = horizontal_speed_lava2
		fall_speed = fall_speed_lava2
	elif cycle_pos >= 11000 and cycle_pos < 12000:
		horizontal_speed = horizontal_speed_lava3
		fall_speed = fall_speed_lava3
	else:
		horizontal_speed = 100.0
		fall_speed = 200.0

	if (cycle_pos > 3000 and cycle_pos <= 4000) or (cycle_pos > 7000 and cycle_pos <= 8000) or (cycle_pos > 11000 and cycle_pos <= 12000):
		depth_bar.value = 0
		reset_zone = true

		if not in_danger_zone:
			in_danger_zone = true
			anim_player.play("DangerPulse")
	else:
		var zone_offset = 0
		if cycle_pos <= 3000:
			zone_offset = 0
		elif cycle_pos <= 7000:
			zone_offset = 4000
		elif cycle_pos <= 11000:
			zone_offset = 8000

		depth_bar.value = cycle_pos - zone_offset
		reset_zone = false

		if in_danger_zone:
			in_danger_zone = false
			if anim_player.is_playing():
				anim_player.stop()

			var fill_stylebox = depth_bar.get("custom_styles/fill")
			if fill_stylebox:
				fill_stylebox.modulate = Color(1, 0, 0)

	update_rock_spawn_speed()

func update_rock_spawn_speed():
	var depth = score % 12000
	if depth >= 3000 and depth < 4000:
		set_rock_spawn_rate(1.0)
	elif depth >= 7000 and depth < 8000:
		set_rock_spawn_rate(0.3)
	elif depth >= 11000 and depth < 12000:
		set_rock_spawn_rate(0.2)
	else:
		set_rock_spawn_rate(3.5)

func set_rock_spawn_rate(rate: float):
	if rock_timer.wait_time != rate:
		rock_timer.wait_time = rate
		rock_timer.start()

func _on_rock_timer_timeout():
	var rock = rock_scene.instantiate()
	var sprite = rock.get_node("Sprite2D")

	var depth = score % 12000

	if depth >= 7000 and depth < 8000:
		sprite.texture = lava2_texture
		rock.fall_speed = fall_speed_lava2
		rock.horizontal_speed = horizontal_speed_lava2
	elif depth >= 11000 and depth < 12000:
		sprite.texture = lava3_texture
		rock.fall_speed = fall_speed_lava3
		rock.horizontal_speed = horizontal_speed_lava3
	else:
		sprite.texture = normal_texture
		rock.fall_speed = fall_speed
		rock.horizontal_speed = horizontal_speed

	$Rocks.add_child(rock)
