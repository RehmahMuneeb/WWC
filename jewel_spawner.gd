extends Node2D

@export var spawn_area: Vector2 = Vector2(800, 600)  # Define the spawn area for jewels
@export var spawn_rate: float = 2.0  # How often jewels are spawned (in seconds)

var jewel_scene: PackedScene
var jewel_textures: Array = []  # Array to hold jewel textures
var timer: Timer

func _ready():
	# Preload the Jewel scene and check if it loads correctly
	jewel_scene = preload("res://Jewels/Jewel.tscn")
	if jewel_scene == null:
		print("Error: Jewel scene failed to preload!")
	else:
		print("Jewel Scene Preloaded: " + str(jewel_scene))  # Check if scene is preloaded

	# Load all jewel textures into an array (12 jewels)
	for i in range(1, 13):  # Loop through numbers 1 to 12 for texture names
		var texture_path = "res://Jewels/Jewel" + str(i) + ".png"
		var texture = load(texture_path)  # Load each texture
		if texture == null:
			print("Error: Could not load texture from path: " + texture_path)  # Debugging if texture load fails
		else:
			jewel_textures.append(texture)  # Add texture to array
	print("Loaded textures: " + str(jewel_textures))  # Check loaded textures

	# Start the spawning process
	start_spawning()

func start_spawning():
	print("Starting spawn process...")  # Confirm that the spawn process is started
	# Create a new timer and start it for spawning jewels at intervals
	timer = Timer.new()
	timer.wait_time = spawn_rate  # Set the spawn rate
	timer.autostart = true  # Make sure it starts automatically
	timer.connect("timeout", Callable(self, "spawn_jewel"))  # Correctly connect to the spawn_jewel function
	add_child(timer)  # Add the timer to the scene

	# Debugging: Print to confirm the timer is added
	print("Timer added to scene: " + str(timer))

func spawn_jewel():
	print("Spawning jewel...")  # Confirm spawn_jewel is triggered

	# Spawn the jewel from the preloaded scene
	var jewel = jewel_scene.instantiate()
	var sprite = jewel.get_node("Sprite2D")  # Get the Sprite node
	if sprite == null:
		print("Error: Sprite2D node not found in Jewel scene!")
		return

	# Randomly pick a texture from the jewel_textures array
	var random_texture = jewel_textures[randi() % jewel_textures.size()]  # Random texture using randi()
	if random_texture != null:
		sprite.texture = random_texture  # Set the random texture on the sprite
		print("Assigned texture: " + str(random_texture))  # Debugging: Check which texture is assigned
	else:
		print("Error: Random texture not found!")  # Handle missing texture
	
	# Set the position of the jewel to fall from a random location at the top of the screen
	jewel.position = Vector2(randi() % int(spawn_area.x), -50)  # Random X, spawn above screen

	# Debugging: Print the position of the jewel
	print("Jewel spawned at position: " + str(jewel.position))

	# Add the jewel to the current scene (parent node) to ensure it's rendered on screen
	self.add_child(jewel)  # Add the jewel to the current node (the spawner node)

	# Debugging: Confirm jewel was added to parent
	print("Jewel added to parent node")
