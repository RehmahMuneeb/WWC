extends CharacterBody2D

const SPEED = 500.0
var is_dragging = false
var drag_start_position = Vector2.ZERO
var drag_previous_position = Vector2.ZERO
const DRAG_THRESHOLD = 6.0  
const MAX_ROTATION = 30.0  # Maximum rotation angle

@onready var jewel_container = $JewelContainer

# Load the shader material
var jewel_shader_material = preload("res://scenes/jewel_shader_material.tres")

func _ready() -> void:
	$Area2D.body_entered.connect(_on_body_entered)
	$AnimationPlayer.play("drop")

func _physics_process(delta: float) -> void:
	if not is_dragging:
		velocity.x = move_toward(velocity.x, 0, SPEED * delta)
		$BucketImage.rotation_degrees = lerp($BucketImage.rotation_degrees, 0.0, 0.1)  # Smoothly reset rotation

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
		# Get the jewel's texture
		var jewel_texture = body.get_node("Sprite2D").texture
		
		# Remove the existing jewel in the container (if any)
		if jewel_container.get_child_count() > 0:
			var existing_jewel = jewel_container.get_child(0)
			jewel_container.remove_child(existing_jewel)
			existing_jewel.queue_free()
		
		# Create a new Sprite2D node with the jewel's texture
		var new_jewel_sprite = Sprite2D.new()
		new_jewel_sprite.texture = jewel_texture
		
		# Apply the shader material to the jewel sprite
		new_jewel_sprite.material = jewel_shader_material
		
		# Add the new Sprite2D to the JewelContainer
		jewel_container.add_child(new_jewel_sprite)
		
		# Position the jewel a little lower (adjust the offset as needed)
		var offset = 22  # Adjust this value to move the jewels lower
		new_jewel_sprite.position = Vector2(0, -jewel_texture.get_height() * 0.3 + offset)
		
		# Remove the original jewel node from the scene
		body.queue_free()
		
		print("Jewel collected!")
		Global.score += 50
		print("Score: ", Global.score)
		
	elif body.is_in_group("stone"):
		print("Stone collided with bucket! Game over!")
		get_tree().quit()
