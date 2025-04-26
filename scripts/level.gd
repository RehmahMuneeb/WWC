extends Node2D

var rock_scene: PackedScene = load("res://scenes/rock.tscn")
var normal_texture = preload("res://assets/rock.png")
var lava2_texture = preload("res://assets/Lavarock88.png")
var lava3_texture = preload("res://assets/Lava-stone-33.png")

var score = 0
var in_danger_zone = false
var reset_zone = false

# Zone management variables
var zone_depths = []  # Stores zone start depths
var zone_types = []    # Stores zone types (0=normal, 1=lava1, 2=lava2)
var current_zone_index = 0
var zone_width = 1000  # How long each zone lasts
var total_zones = 3
var min_zone_gap = 2000  # Minimum space between zones
var safe_start_area = 2000  # No danger zones in first 2000m

@onready var rock_timer = $Rocks/RockTimer
@onready var score_label = $UI/Score
@onready var depth_bar = $UI/ProgressBar
@onready var anim_player = $UI/ProgressBar/AnimationPlayer
@onready var jewel_spawner = $JewelSpawner

func _ready():
	score = 0
	depth_bar.min_value = 0
	depth_bar.max_value = zone_width
	rock_timer.wait_time = 2.0
	rock_timer.start()

	# Randomize zone sequence and depths
	randomize_zones()
	
	var fill_stylebox = depth_bar.get("custom_styles/fill")
	if fill_stylebox:
		fill_stylebox.bg_color = Color(1, 0, 0)

func randomize_zones():
	# Clear existing zones
	zone_depths = []
	zone_types = []
	
	# Create and shuffle zone types
	var types = [0, 1, 2]  # 0=normal, 1=lava1, 2=lava2
	types.shuffle()
	zone_types = types.duplicate()
	
	# Calculate available space (after safe start area)
	var available_space = 12000 - safe_start_area - (total_zones * zone_width) - ((total_zones - 1) * min_zone_gap)
	
	# Create random split points for the available space
	var positions = []
	for i in range(total_zones - 1):
		positions.append(randi_range(0, available_space))
	positions.sort()
	
	# Calculate actual zone start positions (starting after safe area)
	var last_pos = safe_start_area
	for i in range(total_zones):
		var start_pos = safe_start_area
		if i > 0:
			start_pos = positions[i-1] + zone_width + min_zone_gap + safe_start_area
		
		# Add some randomness to the position within its segment
		var segment_start = last_pos
		var segment_end = positions[i] + safe_start_area if i < positions.size() else 12000
		var random_offset = randi_range(0, max(0, segment_end - segment_start - zone_width))
		
		zone_depths.append(segment_start + random_offset)
		last_pos = zone_depths[i] + zone_width + min_zone_gap

func _process(delta):
	score += 1
	score_label.text = str(score) + "m"
	
	var cycle_pos = score % 12000
	
	# Check if we're in any danger zone
	var in_any_danger_zone = false
	var current_zone_type = -1
	
	for i in range(zone_depths.size()):
		if cycle_pos > zone_depths[i] and cycle_pos <= zone_depths[i] + zone_width:
			in_any_danger_zone = true
			current_zone_type = zone_types[i]
			depth_bar.value = 0
			reset_zone = true
			break
	
	if in_any_danger_zone:
		if not in_danger_zone:
			in_danger_zone = true
			# Change pulse color based on zone type
			match current_zone_type:
				0: anim_player.play("DangerPulse")  # Normal zone
				1: anim_player.play("Lava1Pulse")  # Lava zone 1
				2: anim_player.play("Lava2Pulse")  # Lava zone 2
	else:
		# Find which safe zone we're in
		var zone_found = false
		for i in range(zone_depths.size() + 1):
			var zone_start = 0 if i == 0 else zone_depths[i-1] + zone_width
			var zone_end = zone_depths[i] if i < zone_depths.size() else 12000
			
			if cycle_pos >= zone_start and cycle_pos <= zone_end:
				depth_bar.value = cycle_pos - zone_start
				depth_bar.max_value = zone_end - zone_start
				zone_found = true
				break
		
		if not zone_found:
			depth_bar.value = cycle_pos
			depth_bar.max_value = 12000
		
		reset_zone = false
		
		if in_danger_zone:
			in_danger_zone = false
			if anim_player.is_playing():
				anim_player.stop()
			
			var fill_stylebox = depth_bar.get("custom_styles/fill")
			if fill_stylebox:
				fill_stylebox.modulate = Color(1, 0, 0)
	
	update_rock_spawn_speed(cycle_pos)
	update_spawn_rate_based_on_zone(cycle_pos)

func update_rock_spawn_speed(depth: int):
	var spawn_rate = 3.5  # Default spawn rate
	
	# Check if we're in any danger zone and adjust spawn rate
	for i in range(zone_depths.size()):
		if depth >= zone_depths[i] and depth < zone_depths[i] + zone_width:
			match zone_types[i]:
				0: spawn_rate = 1.0   # Normal rock zone
				1: spawn_rate = 0.6   # Lava zone 1
				2: spawn_rate = 0.4   # Lava zone 2
			break
	
	# Special case for ice zone
	if depth >= 1000 and depth < 2000:
		spawn_rate = 1000.0  # Effectively disable spawn
	
	set_rock_spawn_rate(spawn_rate)

func set_rock_spawn_rate(rate: float):
	if rock_timer.wait_time != rate:
		rock_timer.wait_time = rate
		rock_timer.start()

func _on_rock_timer_timeout():
	var depth = score % 12000

	# Prevent rock spawning in the Ice Zone
	if depth >= 1000 and depth < 2000:
		return

	var rock = rock_scene.instantiate()
	var sprite = rock.get_node("Sprite2D")
	var particles = sprite.get_node("GPUParticles2D")

	# Determine which zone we're in (if any)
	var current_zone_type = -1
	for i in range(zone_depths.size()):
		if depth >= zone_depths[i] and depth < zone_depths[i] + zone_width:
			current_zone_type = zone_types[i]
			break

	rock.set_zone(current_zone_type + 1)  # Zones are 1-based

	# Get the ProcessMaterial from the GPUParticles2D node
	var particle_material = particles.process_material

	# Update the rock appearance based on zone type
	match current_zone_type:
		0:  # Normal rock zone
			sprite.texture = normal_texture
			particles.emitting = true
			particle_material.color = Color(1, 1, 1)  # White color
			rock.fall_speed = rock.fall_speed_zone1
			rock.horizontal_speed = rock.horizontal_speed_zone1
		1:  # Lava zone 1
			sprite.texture = lava2_texture
			particles.emitting = true
			particle_material.color = Color(1, 0.6, 0)  # Orange color
			rock.fall_speed = rock.fall_speed_zone2
			rock.horizontal_speed = rock.horizontal_speed_zone2
		2:  # Lava zone 2
			sprite.texture = lava3_texture
			particles.emitting = true
			particle_material.color = Color(1, 0.2, 0)  # Red color
			rock.fall_speed = rock.fall_speed_zone3
			rock.horizontal_speed = rock.horizontal_speed_zone3
		_:  # Default/not in a special zone
			sprite.texture = normal_texture
			particles.emitting = true
			particle_material.color = Color(1, 1, 1)  # White color
			rock.fall_speed = rock.fall_speed_zone1
			rock.horizontal_speed = rock.horizontal_speed_zone1

	$Rocks.add_child(rock)

func update_spawn_rate_based_on_zone(depth: int):
	if depth >= 1000 and depth < 2000:  # Ice Zone
		jewel_spawner.min_spawn_interval = 0.1
		jewel_spawner.max_spawn_interval = 0.3
	else:
		jewel_spawner.min_spawn_interval = 0.5
		jewel_spawner.max_spawn_interval = 2.0
