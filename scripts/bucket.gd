extends CharacterBody2D

const SPEED = 500.0

# Variables to track drag movement
var is_dragging = false
var drag_start_position = Vector2.ZERO
var drag_previous_position = Vector2.ZERO
const DRAG_THRESHOLD = 6.0 # Minimum distance to detect drag

func _physics_process(delta: float) -> void:

	# If not dragging, slow down to a stop
	if not is_dragging:
		velocity.x = move_toward(velocity.x, 0, SPEED * delta)

	move_and_slide()
	

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			# Start dragging
			is_dragging = true
			drag_start_position = event.position
			drag_previous_position = event.position
		else:
			# Stop dragging
			is_dragging = false
			velocity.x = 0 # Stop player movement when touch ends
	
	elif event is InputEventScreenDrag and is_dragging:
		# Calculate drag distance
		var drag_distance = event.position.x - drag_start_position.x

		# Only move if the drag distance exceeds the threshold
		if abs(drag_distance) > DRAG_THRESHOLD:
			velocity.x = sign(drag_distance) * SPEED
			drag_start_position = event.position # Reset start position to prevent continuous movement
		else:
			velocity.x = 0 # Stop movement if below threshold
