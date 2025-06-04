extends Node2D

# Game Objects
var rock_scene: PackedScene = load("res://scenes/rock.tscn")
var normal_texture = preload("res://assets/rock.png")
var lava2_texture = preload("res://STone.png")
var lava3_texture = preload("res://assets/Lava-stone-33.png")

# Game State
var score = 0
var last_cycle = -1
var game_active = true

# Zone Configuration
var zone_depths = []
var zone_types = []
var current_zone_index = 0
var zone_width = 1000
var total_zones = 3
var min_zone_gap = 2000
var safe_start_area = 2000

# Visual Effects
var flashing = false
var flash_elapsed = 0.0
var flash_duration = 12.0
var flash_interval = 0.5
var time_since_last_flash = 0.0
var already_triggered = false

# Node References
@onready var rock_timer = $Rocks/RockTimer
@onready var score_label = $UI/Score
@onready var depth_bar = $UI/ProgressBar
@onready var anim_player = $UI/ProgressBar/AnimationPlayer
@onready var jewel_spawner = $JewelSpawner
@onready var treasure_label = $Treasure
@onready var game_over_panel = $GameOverPanel
@onready var rise_again_button: Button = $GameOverPanel/Panel/RiseAgainButton
@onready var give_up_button: Button = $GameOverPanel/Panel/GiveUpButton
@onready var player = $Bucket

func _ready():
	reset_game_state()
	randomize_zones()
	setup_game_over_panel()

	if player:
		player.connect("player_hit", _on_player_hit)

	var fill_stylebox = depth_bar.get("custom_styles/fill")
	if fill_stylebox:
		fill_stylebox.bg_color = Color(0.2, 0.6, 1.0)

func setup_game_over_panel():
	game_over_panel.visible = false
	rise_again_button.process_mode = Node.PROCESS_MODE_ALWAYS
	give_up_button.process_mode = Node.PROCESS_MODE_ALWAYS
	rise_again_button.pressed.connect(_on_rise_again_pressed)
	give_up_button.pressed.connect(_on_give_up_pressed)

func reset_game_state():
	score = 0
	last_cycle = -1
	game_active = true

	depth_bar.min_value = 0
	depth_bar.max_value = 10000
	rock_timer.wait_time = 2.0
	rock_timer.start()

	treasure_label.visible = false
	flashing = false
	already_triggered = false

	if player:
		player.show()
		player.set_process(true)
		player.set_physics_process(true)
		player.position = Vector2(get_viewport_rect().size.x / 2, get_viewport_rect().size.y - 100)
		player.reset_bucket()

	get_tree().paused = false

func show_game_over():
	game_active = false
	game_over_panel.visible = true
	get_tree().paused = true

	rise_again_button.disabled = false
	give_up_button.disabled = false
	rise_again_button.grab_focus()

func _on_rise_again_pressed():
	print("Rise Again pressed - continuing game")
	game_over_panel.visible = false
	get_tree().paused = false
	game_active = true

func _on_give_up_pressed():
	print("Give Up pressed - returning to menu")
	get_tree().paused = false
	rise_again_button.process_mode = Node.PROCESS_MODE_INHERIT
	give_up_button.process_mode = Node.PROCESS_MODE_INHERIT
	get_tree().change_scene_to_file("res://back_menu.tscn")

func _on_player_hit():
	show_game_over()

func _process(delta):
	if not game_active or get_tree().paused:
		return

	score += 1
	score_label.text = str(score) + "m"

	var current_cycle = score / 11000
	if current_cycle != last_cycle:
		randomize_zones()
		last_cycle = current_cycle
		already_triggered = false

	var cycle_depth = score % 11000
	depth_bar.value = min(cycle_depth, 10000)

	if not already_triggered and depth_bar.value >= depth_bar.max_value:
		handle_bar_completion()

	update_flashing(delta)
	update_rock_spawn_speed(score)
	update_jewel_spawn(score)

func handle_bar_completion():
	if depth_bar.value == depth_bar.max_value and not flashing:
		flashing = true
		already_triggered = true
		flash_elapsed = 0.0
		time_since_last_flash = 0.0
		treasure_label.visible = true
		Global.unlock_next_item()
		print("Unlocked one item at score: ", score)

func update_flashing(delta):
	if flashing:
		flash_elapsed += delta
		time_since_last_flash += delta

		if time_since_last_flash >= flash_interval:
			treasure_label.visible = not treasure_label.visible
			time_since_last_flash = 0.0

		if flash_elapsed >= flash_duration:
			flashing = false
			treasure_label.visible = false

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
			start_pos = positions[i - 1] + zone_width + min_zone_gap + safe_start_area

		var segment_start = last_pos
		var segment_end = positions[i] + safe_start_area if i < positions.size() else 10000
		var random_offset = randi_range(0, max(0, segment_end - segment_start - zone_width))

		zone_depths.append(segment_start + random_offset)
		last_pos = zone_depths[i] + zone_width + min_zone_gap

	print("New zones randomized at depths: ", zone_depths, " with types: ", zone_types)

func update_rock_spawn_speed(depth: int):
	if not game_active:
		return

	var spawn_rate = 3.5
	var cycle_depth = depth % 11000
	var in_ice_zone = cycle_depth >= 10000

	if in_ice_zone:
		spawn_rate = 1000.0
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
		if rate < 1000:
			rock_timer.start()

func _on_rock_timer_timeout():
	if not game_active or get_tree().paused:
		return

	var depth = score
	var cycle_depth = depth % 11000
	var in_ice_zone = cycle_depth >= 10000

	if in_ice_zone:
		return

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
