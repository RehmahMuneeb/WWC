extends Node2D

# Preload the jewel scene
@export var jewel_scene: PackedScene

# Spawn interval range (in seconds)
@export var min_spawn_interval: float = 0.5
@export var max_spawn_interval: float = 2.0

# Maximum number of jewels allowed on screen
@export var max_jewels: int = 12

var is_lava_active = false

func _ready() -> void:
	randomize()
	start_spawn_timer()

func start_spawn_timer():
	# Set a random wait time between min and max
	var random_interval = randf_range(min_spawn_interval, max_spawn_interval)
	$SpawnTimer.wait_time = random_interval
	$SpawnTimer.start()

func _on_spawn_timer_timeout() -> void:
	if is_lava_active:
		return  # Don't spawn jewels if lava is active

	var current_jewels = get_tree().get_nodes_in_group("jewel").size()
	var remaining = max_jewels - current_jewels

	if remaining > 0:
		spawn_jewel()



	start_spawn_timer()

func spawn_jewel() -> void:
	var jewel = jewel_scene.instantiate()

	# Set random initial position
	var viewport_width = get_viewport_rect().size.x
	var spawn_x = randf_range(50, viewport_width - 50)
	var spawn_y = -50  # Just above the screen
	jewel.position = Vector2(spawn_x, spawn_y)

	add_child(jewel)

func set_lava_active(active: bool) -> void:
	is_lava_active = active
