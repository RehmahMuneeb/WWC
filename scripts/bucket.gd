extends CharacterBody2D

signal player_hit

# Adjustable settings
@export var SPEED: float = 700.0
@export var DRAG_THRESHOLD: float = 6.0
@export var MAX_ROTATION: float = 30.0

# State variables
var is_dragging = false
var drag_start_position = Vector2.ZERO
var drag_previous_position = Vector2.ZERO
var collected_jewels = 0

# Nodes
@onready var jewel_container: Node2D = $JewelContainer
@onready var bucket_image: Node2D = $BucketImage
@onready var area2d: Area2D = $Area2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var main = get_tree().root.get_node_or_null("Level")

# Shader for jewels
var jewel_shader_material = preload("res://scenes/jewel_shader_material.tres")

func _ready() -> void:
	area2d.body_entered.connect(_on_body_entered)
	animation_player.play("drop")

func _physics_process(delta: float) -> void:
	if not is_dragging:
		velocity.x = move_toward(velocity.x, 0, SPEED * delta)
		bucket_image.rotation_degrees = lerp(bucket_image.rotation_degrees, 0.0, 0.1)

	move_and_slide()
	jewel_container.rotation_degrees = bucket_image.rotation_degrees  # Sync rotation

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			is_dragging = true
			drag_start_position = event.position
			drag_previous_position = event.position
		else:
			is_dragging = false
			velocity.x = 0

	elif event is InputEventScreenDrag and is_dragging:
		var drag_distance = event.position.x - drag_start_position.x

		if abs(drag_distance) > DRAG_THRESHOLD:
			velocity.x = sign(drag_distance) * SPEED
			drag_start_position = event.position
			bucket_image.rotation_degrees = sign(drag_distance) * MAX_ROTATION
		else:
			velocity.x = 0

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("jewel"):
		if collected_jewels < Global.bucket_capacity:
			var sprite_node = body.get_node_or_null("Sprite2D")
			if sprite_node:
				var jewel_texture = sprite_node.texture
				Global.collect_gem(jewel_texture)

				# Remove existing jewel (only showing one at a time)
				for child in jewel_container.get_children():
					child.queue_free()

				var new_jewel_sprite = Sprite2D.new()
				new_jewel_sprite.texture = jewel_texture
				new_jewel_sprite.material = jewel_shader_material
				new_jewel_sprite.position = Vector2(0, -jewel_texture.get_height() * 0.3 + 25)
				jewel_container.add_child(new_jewel_sprite)

				body.queue_free()
				collected_jewels += 1
				Global.pending_score += 50
				Global.save_game()
				print("Jewel collected! +50 points pending.")

	elif body.is_in_group("stone"):
		print("Stone collided with bucket! Game over.")
		if main and main.has_method("show_game_over"):
			main.show_game_over()
		else:
			get_tree().quit()

func return_to_home() -> void:
	await get_tree().create_timer(1.0).timeout
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func reset_bucket() -> void:
	collected_jewels = 0
	for child in jewel_container.get_children():
		child.queue_free()
	# Optional: update UI inventory if it exists
	var inv_scene_path = "res://Jewels/Inventory.tscn"
	if ResourceLoader.exists(inv_scene_path):
		var inventory_scene = load(inv_scene_path)
		if inventory_scene:
			var inventory_instance = inventory_scene.instantiate()
			if inventory_instance.has_method("update_inventory"):
				inventory_instance.update_inventory()
