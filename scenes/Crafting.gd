extends Control

@onready var item_holder = $Panel/ItemHolder
@onready var item_zoom_panel = $ZoomedItemPanel
@onready var item_name_label = $ZoomedItemPanel/Label
@onready var item_display_container = $ZoomedItemPanel/ItemDisplayContainer
@onready var close_button = $ZoomedItemPanel/CloseButton
@onready var inventory_instance = $Inventory

func _ready():
	item_zoom_panel.visible = false
	inventory_instance.visible = false
	close_button.pressed.connect(_on_close_pressed)
	search_and_connect_texture_rects(item_holder)

func search_and_connect_texture_rects(parent_node: Node):
	for child in parent_node.get_children():
		# Skip inventory items completely
		if parent_node == inventory_instance.rare_gems_list:
			continue
			
		if child is TextureRect:
			child.mouse_filter = Control.MOUSE_FILTER_STOP
			child.connect("gui_input", Callable(self, "_on_item_clicked").bind(child))
		elif child.get_child_count() > 0:
			search_and_connect_texture_rects(child)

func _on_item_clicked(event: InputEvent, item: TextureRect):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		# Additional check to prevent handling inventory items
		var parent = item.get_parent()
		while parent != null:
			if parent == inventory_instance:
				return
			parent = parent.get_parent()

		item_name_label.text = item.name if item.name != "" else "Unnamed Item"

		# Clear previous display
		for c in item_display_container.get_children():
			c.queue_free()

		# Create display clone
		var clone = item.duplicate(true)
		clone.scale = Vector2.ONE
		clone.position = Vector2.ZERO
		item_display_container.add_child(clone)

		await get_tree().process_frame

		# Scale to fit container
		var container_size = item_display_container.size
		var original_size = clone.size

		if original_size.x > 0 and original_size.y > 0:
			var scale_factor = min(
				container_size.x / original_size.x,
				container_size.y / original_size.y
			) * 0.9  # 90% of container to add some padding
			clone.scale = Vector2(scale_factor, scale_factor)
			clone.position = (container_size - (original_size * scale_factor)) / 2

		item_zoom_panel.visible = true
		inventory_instance.visible = true

func _on_close_pressed():
	item_zoom_panel.visible = false
	inventory_instance.visible = false
