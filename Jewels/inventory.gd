extends Control

@onready var rare_gems_list := $ScrollContainer/VBoxContainer

func _ready():
	display_rare_gems()

func display_rare_gems():
	# Clear any previous icons
	for child in rare_gems_list.get_children():
		child.queue_free()

	# Display each rare gem stored globally
	for gem_texture in Global.rare_gems:
		if gem_texture == null:
			continue
		var icon = TextureRect.new()
		icon.texture = gem_texture
		icon.expand = true
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = Vector2(64, 64)
		rare_gems_list.add_child(icon)
