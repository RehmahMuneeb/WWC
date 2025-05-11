extends Control

@export var gem_texture_paths: Array = []
var gem_texture_rect: TextureRect

func _ready():
	# Load all gem textures from the "raregems" folder
	var gem_folder = "res://raregems/"
	var dir = DirAccess.open(gem_folder)  # Using DirAccess instead of Directory
	if dir != null:
		dir.list_dir_begin()  # No need for extra arguments here
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".png"):  # Ensure it's a .png file
				gem_texture_paths.append(gem_folder + file_name)
			file_name = dir.get_next()
		dir.list_dir_end()

	# Now select a random gem from the list and set it as the texture
	if gem_texture_paths.size() > 0:
		var random_index = randi() % gem_texture_paths.size()
		var selected_texture = load(gem_texture_paths[random_index])

		# Find the TextureRect in the scene and set the selected texture
		gem_texture_rect = $Panel/TextureRect  # Assuming this is the TextureRect in your scene
		gem_texture_rect.texture = selected_texture
