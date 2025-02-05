extends Node2D

# Preload the jewel scene
@export var jewel_scene: PackedScene

# Spawn interval in seconds
@export var spawn_interval: float = 1.0

# Maximum number of jewels allowed on screen
@export var max_jewels: int = 12

func _ready() -> void:
	# Start the spawn timer
	$SpawnTimer.wait_time = spawn_interval
	$SpawnTimer.start()

func _on_spawn_timer_timeout() -> void:
	# Check how many jewels are currently in the scene
	var current_jewels = get_tree().get_nodes_in_group("jewel").size()

	# Spawn a new jewel if the maximum number hasn't been reached
	if current_jewels < max_jewels:
		spawn_jewel()

func spawn_jewel() -> void:
	var jewel = jewel_scene.instantiate()
	
	# Set the initial position of the jewel
	var viewport_width = get_viewport_rect().size.x
	var spawn_x = randf_range(50, viewport_width - 50)  # Random x position within the screen width
	var spawn_y = -50  # Spawn above the top edge of the screen
	jewel.position = Vector2(spawn_x, spawn_y)
	
	add_child(jewel)
