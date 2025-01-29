extends Node2D

# Array holding the Rect2 regions for each jewel
var jewel_regions = [
	Rect2(0, 0, 128, 128),       # Jewel 1 (Top-left)
	Rect2(128, 0, 128, 128),     # Jewel 2 (Top-center)
	Rect2(256, 0, 128, 128),     # Jewel 3 (Top-right)
	Rect2(384, 0, 128, 128),     # Jewel 4 (Top-rightmost)
	Rect2(0, 128, 128, 128),     # Jewel 5 (Middle-left)
	Rect2(128, 128, 128, 128),   # Jewel 6 (Middle-center)
	Rect2(256, 128, 128, 128),   # Jewel 7 (Middle-right)
	Rect2(384, 128, 128, 128),   # Jewel 8 (Middle-rightmost)
	Rect2(0, 256, 128, 128),     # Jewel 9 (Bottom-left)
	Rect2(128, 256, 128, 128),   # Jewel 10 (Bottom-center)
	Rect2(256, 256, 128, 128),   # Jewel 11 (Bottom-right)
	Rect2(384, 256, 128, 128)    # Jewel 12 (Bottom-rightmost)
]

# Path to the AtlasTexture resource
var atlas_texture_path = "res://scenes/jewels_atlas.tres"

# Max number of jewels on the screen
var max_jewels = 5
var jewels_on_screen = []
var spawn_timer = 0.0
var spawn_interval = 1.0  # Interval in seconds between jewel spawns

# Screen boundaries
var screen_left_boundary = 50
var screen_right_boundary = 0

func _ready():
	# Start the jewel spawning process
	spawn_timer = spawn_interval
	
	var screen_size = get_viewport_rect().size
	screen_right_boundary = screen_size.x - 50

# This function is called every frame
func _process(delta):
	# Update the spawn timer
	spawn_timer -= delta

	# Check if it's time to spawn a new jewel
	if spawn_timer <= 0.0 and jewels_on_screen.size() < max_jewels:
		spawn_jewel()
		spawn_timer = spawn_interval  # Reset the timer for the next spawn

	# Update positions of jewels on screen
	for child in jewels_on_screen:
		if child is Sprite2D and child.has_meta("velocity"):
			# Update position based on velocity
			var velocity = child.get_meta("velocity") as Vector2
			child.position += velocity * delta

			# Check if the jewel is off-screen (vertically)
			if child.position.y > get_viewport().size.y + 50:
				# Remove jewel from the scene when it falls off-screen
				child.queue_free()
				jewels_on_screen.erase(child)

			# Horizontal boundary check (left and right walls)
			if child.position.x <= screen_left_boundary or child.position.x >= screen_right_boundary:
				# Reverse horizontal velocity when hitting the left or right boundary (bouncing effect)
				velocity.x = -velocity.x  # Reverse the horizontal movement
				child.set_meta("velocity", velocity)  # Update the jewel's velocity

# Function to spawn a single jewel
func spawn_jewel():
	# Create a new jewel node (Sprite2D)
	var jewel = create_jewel()

	# Add the jewel to the scene and track it
	add_child(jewel)
	jewels_on_screen.append(jewel)

# Helper function to create and return a jewel Sprite2D
func create_jewel() -> Sprite2D:
	var jewel = Sprite2D.new()

	# Create a new AtlasTexture instance for this jewel
	var atlas_texture = load(atlas_texture_path).duplicate() as AtlasTexture

	# Randomly select one of the jewel regions
	var random_index = randi() % jewel_regions.size()
	atlas_texture.region = jewel_regions[random_index]

	# Assign the unique texture to the sprite
	jewel.texture = atlas_texture

	# Store the region index and velocity as metadata
	jewel.set_meta("region_index", random_index)
	
	# Assign random horizontal velocity for the floating effect (fixed vertical velocity)
	var horizontal_velocity = randf_range(-250, 250)  # X velocity between -250 and 250
	var vertical_velocity = randf_range(400, 500)    # Fixed Y velocity (falling speed)
	jewel.set_meta("velocity", Vector2(horizontal_velocity, vertical_velocity))

	# Set the spawn position
	jewel.position = Vector2(randf_range(0, get_viewport().size.x), -50)  # Random X, above the screen

	# Enable _process for the jewel
	jewel.set_process(true)

	return jewel

func _on_jewel_timer_timeout() -> void:
	pass # Replace with function body.
