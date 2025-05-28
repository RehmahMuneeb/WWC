extends Control

@onready var item_holder = $Panel/ItemHolder
@onready var item_zoom_panel = $ZoomedItemPanel
@onready var item_name_label = $ZoomedItemPanel/Label
@onready var item_display_container = $ZoomedItemPanel/ItemDisplayContainer
@onready var close_button = $ZoomedItemPanel/CloseButton
@onready var inventory_instance = $Inventory

var current_zoomed_item: TextureRect = null
var zoom_panel_overlays = []
var overlay_map = {}
var previously_unlocked_items = []

func _ready():
	setup_ui()
	initialize_items()
	connect_signals()

func setup_ui():
	item_zoom_panel.visible = false
	inventory_instance.visible = false

func initialize_items():
	lock_all_items()
	previously_unlocked_items = Global.unlocked_items.duplicate()
	update_unlocked_items()

func connect_signals():
	close_button.pressed.connect(_on_close_pressed)

func _process(delta):
	check_for_new_unlocks()

func check_for_new_unlocks():
	if Global.unlocked_items.size() > previously_unlocked_items.size():
		var new_items = []
		for item in Global.unlocked_items:
			if not item in previously_unlocked_items:
				new_items.append(item)
		previously_unlocked_items = Global.unlocked_items.duplicate()
		for item in new_items:
			unlock_item(item)

func update_unlocked_items():
	for item_name in Global.unlocked_items:
		unlock_item(item_name)

func lock_all_items():
	_for_each_item(item_holder, func(item: TextureRect):
		var lock = item.get_node_or_null("LockOverlay")
		if lock:
			lock.visible = true
		item.mouse_filter = Control.MOUSE_FILTER_IGNORE
	)

func unlock_item(item_name: String):
	var item = find_item_by_name(item_holder, item_name)
	if item:
		var lock = item.get_node_or_null("LockOverlay")
		if lock:
			lock.visible = false
		item.mouse_filter = Control.MOUSE_FILTER_STOP
		if not item.is_connected("gui_input", _on_item_clicked):
			item.gui_input.connect(_on_item_clicked.bind(item))

func find_item_by_name(node: Node, name: String) -> TextureRect:
	if node.name == name and node is TextureRect:
		return node
	for child in node.get_children():
		var found = find_item_by_name(child, name)
		if found:
			return found
	return null

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
		overlay_map.clear()

		# Duplicate the item with children
		var clone = item.duplicate(true)
		clone.scale = Vector2.ONE
		clone.position = Vector2.ZERO
		item_display_container.add_child(clone)

		# Register black overlays in the clone and original
		register_zoom_panel_overlays(clone, item)

		await get_tree().process_frame  # Wait one frame for size update

		# Scale clone to fit container nicely
		var container_size = item_display_container.size
		var original_size = clone.size

		if original_size.x > 0 and original_size.y > 0:
			var scale_factor = min(container_size.x / original_size.x, container_size.y / original_size.y) * 0.9
			clone.scale = Vector2(scale_factor, scale_factor)
			clone.position = (container_size - (original_size * scale_factor)) / 2

		item_zoom_panel.visible = true
		inventory_instance.visible = true

func register_zoom_panel_overlays(clone_node: Node, original_node: Node = null):
	if clone_node is TextureRect:
		if _is_black_overlay(clone_node):
			clone_node.add_to_group("black_overlays")
			zoom_panel_overlays.append(clone_node)
			clone_node.mouse_filter = Control.MOUSE_FILTER_STOP
			if original_node:
				overlay_map[clone_node] = original_node

	var original_children = original_node.get_children() if original_node else []
	var clone_children = clone_node.get_children()

	for i in range(clone_children.size()):
		var orig_child = original_children[i] if i < original_children.size() else null
		register_zoom_panel_overlays(clone_children[i], orig_child)

func _is_black_overlay(node: TextureRect) -> bool:
	return "black" in node.name.to_lower() or \
		   (node.texture and "black_overlay" in node.texture.resource_path.to_lower())

func _on_close_pressed():
	item_zoom_panel.visible = false
	inventory_instance.visible = false
	current_zoomed_item = null

func _for_each_item(node: Node, action: Callable):
	for child in node.get_children():
		if child is TextureRect:
			action.call(child)
		elif child.get_child_count() > 0:
			_for_each_item(child, action)

# 🟡 Utility for gem placement logic
func get_black_overlay_at_position(global_pos: Vector2) -> TextureRect:
	for overlay in zoom_panel_overlays:
		if overlay.get_global_rect().has_point(global_pos):
			return overlay
	return null
