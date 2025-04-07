extends Control

@onready var item_container := $ScrollContainer/HBoxContainer

signal gem_clicked(texture)

func _ready():
	update_inventory()

func update_inventory():
	# Clear existing items
	for child in item_container.get_children():
		child.queue_free()

	# Add each gem as a TextureButton
	for texture in Global.collected_gems:
		print("Adding gem to inventory: ", texture)

		var gem_button = TextureButton.new()
		gem_button.texture_normal = texture
		gem_button.custom_minimum_size = Vector2(64, 64)  # Sets size of the button
		gem_button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED

		# Connect click
		gem_button.connect("pressed", Callable(self, "_on_gem_clicked").bind(texture))

		item_container.add_child(gem_button)

func _on_gem_clicked(texture):
	print("Gem clicked: ", texture)
	emit_signal("gem_clicked", texture)  # You can handle selling using this signal
