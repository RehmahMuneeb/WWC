extends Control

@onready var first_row := $ScrollContainer/VBoxContainer/HBoxContainer
@onready var second_row := $ScrollContainer/VBoxContainer/HBoxContainer2

signal gem_clicked(texture)

func _ready():
	update_inventory()

func update_inventory():
	# Clear existing items
	for child in first_row.get_children():
		child.queue_free()
	for child in second_row.get_children():
		child.queue_free()

	# Count each unique gem texture
	var gem_counts := {}
	for gem in Global.collected_gems:
		gem_counts[gem] = gem_counts.get(gem, 0) + 1

	var gem_idx = 0
	var half = int(gem_counts.size() / 2.0 + 0.5)

	for gem_texture in gem_counts.keys():
		var count = gem_counts[gem_texture]

		# Create TextureButton
		var gem_button = TextureButton.new()
		gem_button.texture_normal = gem_texture
		gem_button.custom_minimum_size = Vector2(64, 64)
		gem_button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		gem_button.connect("pressed", Callable(self, "_on_gem_clicked").bind(gem_texture))

		# Tooltip version (optional)
		gem_button.tooltip_text = "x" + str(count)

		# Add small label for count
		if count > 1:
			var label = Label.new()
			label.text = "x" + str(count)
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
			label.anchor_right = 1.0
			label.anchor_bottom = 1.0
			label.offset_right = -5
			label.offset_bottom = -5
			label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			gem_button.add_child(label)

		if gem_idx < half:
			first_row.add_child(gem_button)
		else:
			second_row.add_child(gem_button)

		gem_idx += 1

func _on_gem_clicked(texture):
	print("Gem clicked: ", texture)
	emit_signal("gem_clicked", texture)
