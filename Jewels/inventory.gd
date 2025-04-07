extends Control

@onready var first_row := $ScrollContainer/VBoxContainer/HBoxContainer
@onready var second_row := $ScrollContainer/VBoxContainer/HBoxContainer2

signal gem_clicked(texture)

func _ready():
	update_inventory()

func update_inventory():
	# Clear existing items in both rows
	for child in first_row.get_children():
		child.queue_free()
	for child in second_row.get_children():
		child.queue_free()

	# Distribute gems between two rows
	var gem_count = Global.collected_gems.size()
	var half_count = int(gem_count / 2)

	# Add gems to the first row
	for i in range(half_count):
		var texture = Global.collected_gems[i]
		var gem_button = TextureButton.new()
		gem_button.texture_normal = texture
		gem_button.custom_minimum_size = Vector2(64, 64)  # Sets size of the button
		gem_button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED

		# Connect click
		gem_button.connect("pressed", Callable(self, "_on_gem_clicked").bind(texture))

		first_row.add_child(gem_button)

	# Add gems to the second row
	for i in range(half_count, gem_count):
		var texture = Global.collected_gems[i]
		var gem_button = TextureButton.new()
		gem_button.texture_normal = texture
		gem_button.custom_minimum_size = Vector2(64, 64)  # Sets size of the button
		gem_button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED

		# Connect click
		gem_button.connect("pressed", Callable(self, "_on_gem_clicked").bind(texture))

		second_row.add_child(gem_button)

func _on_gem_clicked(texture):
	print("Gem clicked: ", texture)
	emit_signal("gem_clicked", texture)  # You can handle selling using this signal
