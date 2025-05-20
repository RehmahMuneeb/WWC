extends Control

@onready var item_holder = $Panel/ItemHolder
@onready var item_zoom_panel = $ZoomedItemPanel
@onready var item_name_label = $ZoomedItemPanel/Label
@onready var item_display_container = $ZoomedItemPanel/ItemDisplayContainer
@onready var close_button = $ZoomedItemPanel/CloseButton
@onready var inventory_instance = $Inventory

var current_zoomed_item: TextureRect = null
var zoom_panel_overlays = []

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
		# Skip inventory gems
		if item.get_parent().get_parent() == inventory_instance.rare_gems_list:
			return

		current_zoomed_item = item
		item_name_label.text = item.name if item.name != "" else "Unnamed Item"

		# Clear previous zoom display
		for c in item_display_container.get_children():
			c.queue_free()
		zoom_panel_overlays.clear()

		# Duplicate the item with children
		var clone = item.duplicate(true)
		clone.scale = Vector2.ONE
		clone.position = Vector2.ZERO
		item_display_container.add_child(clone)

		# Dynamically add "black_overlays" group to relevant children in the clone
		register_zoom_panel_overlays(clone)

		await get_tree().process_frame  # Wait for one frame so sizes are updated

		# Scale clone to fit container nicely
		var container_size = item_display_container.size
		var original_size = clone.size

		if original_size.x > 0 and original_size.y > 0:
			var scale_factor = min(container_size.x / original_size.x, container_size.y / original_size.y) * 0.9
			clone.scale = Vector2(scale_factor, scale_factor)
			clone.position = (container_size - (original_size * scale_factor)) / 2

		item_zoom_panel.visible = true
		inventory_instance.visible = true

func register_zoom_panel_overlays(node: Node):
	# Detect black overlay nodes by texture or name, add to group, register for drag-drop
	if node is TextureRect:
		if _is_black_overlay(node):
			node.add_to_group("black_overlays")
			zoom_panel_overlays.append(node)
			node.mouse_filter = Control.MOUSE_FILTER_STOP
	for child in node.get_children():
		register_zoom_panel_overlays(child)

func _is_black_overlay(node: TextureRect) -> bool:
	# Customize this detection to your actual black overlay texture or node name
	# Example 1: Check node name:
	if "black" in node.name.to_lower():
		return true
	# Example 2: Check texture file name (replace 'black_overlay.png' with your file)
	if node.texture and node.texture.get_path().to_lower().ends_with("black_overlay.png"):
		return true
	return false

func get_black_overlay_at_position(pos: Vector2) -> TextureRect:
	for overlay in zoom_panel_overlays:
		if overlay.get_global_rect().has_point(pos):
			return overlay
	return null

func remove_black_overlay(overlay: TextureRect):
	overlay.visible = false

func _on_close_pressed():
	item_zoom_panel.visible = false
	inventory_instance.visible = false
	current_zoomed_item = null
	zoom_panel_overlays.clear()
