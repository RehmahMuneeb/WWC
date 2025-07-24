extends Node2D

# Jewel spawning
@export var jewel_scene: PackedScene
@export var min_spawn_interval: float = 0.5
@export var max_spawn_interval: float = 2.0
@export var max_jewels: int = 12

# Key spawning
@export var key_scene: PackedScene         # Drag and drop Key.tscn in the Inspector
@export var key_spawn_interval: float = 2.0  # Seconds between key spawns

var is_lava_active = false

func _ready() -> void:
	randomize()
	start_spawn_timer()
	start_key_timer()

func start_spawn_timer():
	var random_interval = randf_range(min_spawn_interval, max_spawn_interval)
	$SpawnTimer.wait_time = random_interval
	$SpawnTimer.start()

func start_key_timer():
	$KeySpawnTimer.wait_time = key_spawn_interval
	$KeySpawnTimer.start()

func _on_spawn_timer_timeout() -> void:
	if is_lava_active:
		return  # Don't spawn jewels if lava is active

	var current_jewels = get_tree().get_nodes_in_group("jewel").size()
	var remaining = max_jewels - current_jewels

	if remaining > 0:
		spawn_jewel()

	start_spawn_timer()

func spawn_jewel() -> void:
	if jewel_scene:
		var jewel = jewel_scene.instantiate()
		var viewport_width = get_viewport_rect().size.x
		var spawn_x = randf_range(50, viewport_width - 50)
		var spawn_y = -50  # Spawn above the screen
		jewel.position = Vector2(spawn_x, spawn_y)
		add_child(jewel)

func spawn_key() -> void:
	if key_scene:
		var key = key_scene.instantiate()
		var viewport_width = get_viewport_rect().size.x
		var spawn_x = randf_range(50, viewport_width - 50)
		var spawn_y = -60
		key.position = Vector2(spawn_x, spawn_y)
		add_child(key)

func _on_key_spawn_timer_timeout() -> void:
	if is_lava_active:
		return  # Do
	spawn_key()
	start_key_timer()


func set_lava_active(active: bool) -> void:
	is_lava_active = active
