extends Control

@onready var item_holder = $Panel/ItemHolder
@onready var item_zoom_panel = $ZoomedItemPanel
@onready var item_name_label = $ZoomedItemPanel/Label
@onready var item_display_container = $ZoomedItemPanel/ItemDisplayContainer
@onready var close_button = $ZoomedItemPanel/CloseButton
@onready var inventory_instance = $ZoomedItemPanel/Inventory

func _ready():
	item_zoom_panel.visible = false
	inventory_instance.visible = false
	close_button.pressed.connect(_on_close_pressed)
	search_and_connect_texture_rects(item_holder)

func search_and_connect_texture_rects(parent_node: Node):
	for child in parent_node.get_children():
		if child is TextureRect:
			child.mouse_filter = Control.MOUSE_FILTER_STOP
			child.connect("gui_input", Callable(self, "_on_item_clicked").bind(child))
		elif child.get_child_count() > 0:
			search_and_connect_texture_rects(child)

func _on_item_clicked(event: InputEvent, item: TextureRect):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		item_name_label.text = item.name if item.name != "" else "Unnamed Item"

		# Clear previous display
		for c in item_display_container.get_children():
			c.queue_free()

		# Duplicate the full item with its children (like slot overlays)
		var clone = item.duplicate(true)
		clone.scale = Vector2.ONE
		clone.position = Vector2.ZERO
		item_display_container.add_child(clone)

		await get_tree().process_frame  # Wait one frame for size info

		# Scale to fit the container
		var container_size = item_display_container.size
		var original_size = clone.size

		if original_size.x > 0 and original_size.y > 0:
			var scale_x = container_size.x / original_size.x
			var scale_y = container_size.y / original_size.y
			var final_scale = min(scale_x, scale_y)
			clone.scale = Vector2(final_scale, final_scale)

			var new_size = original_size * final_scale
			clone.position = (container_size - new_size) / 2

		item_zoom_panel.visible = true
		inventory_instance.visible = true

func _on_close_pressed():
	item_zoom_panel.visible = false
	inventory_instance.visible = false
