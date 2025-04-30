extends Node2D

var rock_scene: PackedScene = load("res://scenes/rock.tscn")
var normal_texture = preload("res://assets/rock.png")
var lava2_texture = preload("res://assets/Lavarock88.png")
var lava3_texture = preload("res://assets/Lava-stone-33.png")

var score = 0
var last_cycle = -1

var zone_depths = []
var zone_types = []
var current_zone_index = 0
var zone_width = 1000
var total_zones = 3
var min_zone_gap = 2000
var safe_start_area = 2000

@onready var rock_timer = $Rocks/RockTimer
@onready var score_label = $UI/Score
@onready var depth_bar = $UI/ProgressBar
@onready var anim_player = $UI/ProgressBar/AnimationPlayer
@onready var jewel_spawner = $JewelSpawner

func _ready():
	score = 0
	last_cycle = -1
	depth_bar.min_value = 0
	depth_bar.max_value = 10000
	rock_timer.wait_time = 2.0
	rock_timer.start()

	randomize_zones()

	var fill_stylebox = depth_bar.get("custom_styles/fill")
	if fill_stylebox:
		fill_stylebox.bg_color = Color(0.2, 0.6, 1.0)

func randomize_zones():
	zone_depths = []
	zone_types = []

	var types = [0, 1, 2]
	types.shuffle()
	zone_types = types.duplicate()

	var available_space = 10000 - safe_start_area - (total_zones * zone_width) - ((total_zones - 1) * min_zone_gap)

	var positions = []
	for i in range(total_zones - 1):
		positions.append(randi_range(0, available_space))
	positions.sort()

	var last_pos = safe_start_area
	for i in range(total_zones):
		var start_pos = safe_start_area
		if i > 0:
			start_pos = positions[i-1] + zone_width + min_zone_gap + safe_start_area

		var segment_start = last_pos
		var segment_end = positions[i] + safe_start_area if i < positions.size() else 10000
		var random_offset = randi_range(0, max(0, segment_end - segment_start - zone_width))

		zone_depths.append(segment_start + random_offset)
		last_pos = zone_depths[i] + zone_width + min_zone_gap

	print("New zones randomized at depths: ", zone_depths, " with types: ", zone_types)

func _process(delta):
	score += 1
	score_label.text = str(score) + "m"

	var current_cycle = score / 11000
	if current_cycle != last_cycle:
		randomize_zones()
		last_cycle = current_cycle

	var cycle_depth = score % 11000
	if cycle_depth < 10000:
		depth_bar.value = cycle_depth
	else:
		depth_bar.value = 10000  # Keep it full during Ice Zone

	update_rock_spawn_speed(score)
	update_jewel_spawn(score)

func update_rock_spawn_speed(depth: int):
	var spawn_rate = 3.5
	var cycle_depth = depth % 11000
	var in_ice_zone = cycle_depth >= 10000

	if in_ice_zone:
		spawn_rate = 1000.0  # Effectively disables rock spawn
	else:
		for i in range(zone_depths.size()):
			if cycle_depth >= zone_depths[i] and cycle_depth < zone_depths[i] + zone_width:
				match zone_types[i]:
					0: spawn_rate = 1.0
					1: spawn_rate = 0.6
					2: spawn_rate = 0.5
				break

	set_rock_spawn_rate(spawn_rate)

func set_rock_spawn_rate(rate: float):
	if rock_timer.wait_time != rate:
		rock_timer.wait_time = rate
		if rate < 1000:  # Only restart if not in ice zone
			rock_timer.start()

func _on_rock_timer_timeout():
	var depth = score
	var cycle_depth = depth % 11000
	var in_ice_zone = cycle_depth >= 10000

	if in_ice_zone:
		return  # Do not spawn rocks during Ice Zone

	var rock = rock_scene.instantiate()
	var sprite = rock.get_node("Sprite2D")
	var particles = sprite.get_node("GPUParticles2D")

	var current_zone_type = -1
	for i in range(zone_depths.size()):
		if cycle_depth >= zone_depths[i] and cycle_depth < zone_depths[i] + zone_width:
			current_zone_type = zone_types[i]
			break

	rock.set_zone(current_zone_type + 1)

	var particle_material = particles.process_material

	match current_zone_type:
		0:
			sprite.texture = normal_texture
			particles.emitting = true
			particle_material.color = Color(1, 1, 1)
			rock.fall_speed = rock.fall_speed_zone1
			rock.horizontal_speed = rock.horizontal_speed_zone1
		1:
			sprite.texture = lava2_texture
			particles.emitting = true
			particle_material.color = Color(1, 0.6, 0)
			rock.fall_speed = rock.fall_speed_zone2
			rock.horizontal_speed = rock.horizontal_speed_zone2
		2:
			sprite.texture = lava3_texture
			particles.emitting = true
			particle_material.color = Color(1, 0.2, 0)
			rock.fall_speed = rock.fall_speed_zone3
			rock.horizontal_speed = rock.horizontal_speed_zone3
		_:
			sprite.texture = normal_texture
			particles.emitting = true
			particle_material.color = Color(1, 1, 1)
			rock.fall_speed = rock.fall_speed_zone1
			rock.horizontal_speed = rock.horizontal_speed_zone1

	$Rocks.add_child(rock)

func update_jewel_spawn(depth: int):
	var cycle_depth = depth % 11000
	var in_ice_zone = cycle_depth >= 10000

	if in_ice_zone:
		jewel_spawner.min_spawn_interval = 0.1
		jewel_spawner.max_spawn_interval = 0.3
	else:
		jewel_spawner.min_spawn_interval = 0.5
		jewel_spawner.max_spawn_interval = 2.0
