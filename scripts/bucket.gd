extends CharacterBody2D
signal player_hit
const SPEED = 700.0
var is_dragging = false
var drag_start_position = Vector2.ZERO
var drag_previous_position = Vector2.ZERO
const DRAG_THRESHOLD = 6.0  
const MAX_ROTATION = 30.0  

var collected_jewels = 0  # Count collected jewels

@onready var jewel_container = $JewelContainer
@onready var main = get_tree().root.get_node("Level")  # Reference to main game script

# Load the shader material
var jewel_shader_material = preload("res://scenes/jewel_shader_material.tres")

func _ready() -> void:
	$Area2D.body_entered.connect(_on_body_entered)
	$AnimationPlayer.play("drop")

func _physics_process(delta: float) -> void:
	if not is_dragging:
		velocity.x = move_toward(velocity.x, 0, SPEED * delta)
		$BucketImage.rotation_degrees = lerp($BucketImage.rotation_degrees, 0.0, 0.1)  

	move_and_slide()
	
	# Synchronize jewel rotation with bucket rotation
	jewel_container.rotation_degrees = $BucketImage.rotation_degrees

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
			
			# Rotate bucket based on movement direction
			$BucketImage.rotation_degrees = sign(drag_distance) * MAX_ROTATION
		else:
			velocity.x = 0  

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("jewel"):
		if collected_jewels < Global.bucket_capacity:  # Check if bucket has space
			var jewel_texture = body.get_node("Sprite2D").texture

			# Add jewel texture to Global collected gems
			Global.collect_gem(jewel_texture)

			# If there's already a jewel, remove it before adding new one
			if jewel_container.get_child_count() > 0:
				var existing_jewel = jewel_container.get_child(0)
				jewel_container.remove_child(existing_jewel)
				existing_jewel.queue_free()

			# Create and add new jewel sprite to the bucket container
			var new_jewel_sprite = Sprite2D.new()
			new_jewel_sprite.texture = jewel_texture
			new_jewel_sprite.material = jewel_shader_material
			jewel_container.add_child(new_jewel_sprite)
			
			# Set the new jewel's position inside the bucket
			var offset = 25  
			new_jewel_sprite.position = Vector2(0, -jewel_texture.get_height() * 0.3 + offset)

			# Remove the jewel from the scene (i.e., the original jewel object)
			body.queue_free()
			
			collected_jewels += 1  
			Global.pending_score += 50
			Global.save_game()  # Save progress
			print("Jewel collected! Score will be added gradually.")

	elif body.is_in_group("stone"):
		print("Stone collided with bucket! Game over!")
		if main:
			main.show_game_over()  # Call the game over function in main script
		else:
			get_tree().quit()  # Fallback if main script isn't found

func return_to_home():
	await get_tree().create_timer(1.0).timeout  # Wait 1 second before switching
	get_tree().change_scene_to_file("res://scenes/main.tscn")  # Go to home screen

func reset_bucket():
	collected_jewels = 0  # Reset jewels when restarting level
	if has_node("res://Jewels/Inventory.tscn"):
		get_node("res://Jewels/Inventory.tscn").update_inventory()
