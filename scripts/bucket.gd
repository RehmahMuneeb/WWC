extends CharacterBody2D

signal player_hit

# Adjustable settings
@export var SPEED: float = 1000.0
@export var VERTICAL_SPEED: float = 600.0
@export var DRAG_THRESHOLD: float = 10.0
@export var MAX_ROTATION: float = 35.0

# State variables
var is_dragging = false
var touch_id = -1
var drag_start_position = Vector2.ZERO
var drag_previous_position = Vector2.ZERO
var collected_jewels = 0
var target_rotation := 0.0

# Nodes
@onready var jewel_container: Node2D = $JewelContainer
@onready var bucket_image: Node2D = $BucketImage
@onready var area2d: Area2D = $Area2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var main = get_tree().root.get_node_or_null("Level")
@onready var jewel_collect_sound: AudioStreamPlayer2D = $JewelCollectSound
@onready var rock_hit_sound: AudioStreamPlayer2D = $RockHitSound

# Shader for jewels
var jewel_shader_material = preload("res://scenes/jewel_shader_material.tres")

func _ready() -> void:
	area2d.body_entered.connect(_on_body_entered)
	animation_player.play("drop")
	randomize()

func _physics_process(delta: float) -> void:
	if not is_dragging:
		# Apply gentle deceleration when not dragging
		velocity.x = move_toward(velocity.x, 0, SPEED * delta)
		velocity.y = move_toward(velocity.y, 0, VERTICAL_SPEED * delta)
		target_rotation = 0.0  # Return to upright when not dragging

	# Smoothly rotate the bucket toward target_rotation
	bucket_image.rotation_degrees = lerp(bucket_image.rotation_degrees, target_rotation, 0.1)
	jewel_container.rotation_degrees = bucket_image.rotation_degrees

	move_and_slide()

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and touch_id == -1:  # Only track one finger
			touch_id = event.index
			is_dragging = true
			drag_start_position = event.position
			drag_previous_position = event.position
		elif not event.pressed and event.index == touch_id:
			is_dragging = false
			touch_id = -1
			# Apply some momentum based on last movement
			velocity = velocity * 0.5  # Reduce velocity by half when releasing

	elif event is InputEventScreenDrag and is_dragging and event.index == touch_id:
		var delta_position = event.position - drag_previous_position
		
		# Only start moving if drag distance exceeds threshold
		if delta_position.length() > DRAG_THRESHOLD or velocity.length() > 0:
			var delta_time = get_physics_process_delta_time()
			if delta_time > 0:
				# Apply movement in both axes
				velocity.x = delta_position.x / delta_time
				velocity.y = delta_position.y / delta_time

				var max_horizontal_speed = 1500.0
				var max_vertical_speed = 1200.0
				velocity.x = clamp(velocity.x, -max_horizontal_speed, max_horizontal_speed)
				velocity.y = clamp(velocity.y, -max_vertical_speed, max_vertical_speed)

				# Set target rotation based on horizontal movement only
				target_rotation = clamp(velocity.x / 10.0, -MAX_ROTATION, MAX_ROTATION)

				drag_previous_position = event.position

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("jewel"):
		if collected_jewels < Global.bucket_capacity:
			var sprite_node = body.get_node_or_null("Sprite2D")
			if sprite_node:
				var jewel_texture = sprite_node.texture
				Global.collect_gem(jewel_texture)

				var new_jewel_sprite = Sprite2D.new()
				new_jewel_sprite.texture = jewel_texture
				new_jewel_sprite.material = jewel_shader_material

				var scatter_area_width = 60
				var scatter_area_height = 5
				var offset_x = randf_range(-scatter_area_width / 2, scatter_area_width / 2)
				var offset_y = randf_range(-scatter_area_height, 0)
				new_jewel_sprite.position = Vector2(offset_x, offset_y)
				new_jewel_sprite.scale = Vector2(0.5, 0.5)

				jewel_container.add_child(new_jewel_sprite)

				body.queue_free()
				collected_jewels += 1
				Global.pending_score += 50
				Global.save_game()

				jewel_collect_sound.play()


				var visible_limit = 30
				var children_to_remove = max(0, collected_jewels - visible_limit)
				while children_to_remove > 0 and jewel_container.get_child_count() > 0:
					var oldest = jewel_container.get_child(0)
					oldest.queue_free()
					children_to_remove -= 1
	elif body.is_in_group("key"):

		Global.key_score += 1  # New key score
		body.queue_free()
		
	elif body.is_in_group("stone"):

		rock_hit_sound.play()
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
	var inv_scene_path = "res://Jewels/Inventory.tscn"
	if ResourceLoader.exists(inv_scene_path):
		var inventory_scene = load(inv_scene_path)
		if inventory_scene:
			var inventory_instance = inventory_scene.instantiate()
			if inventory_instance.has_method("update_inventory"):
				inventory_instance.update_inventory()
