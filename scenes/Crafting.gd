extends Control

@onready var item_holder = $Panel/ItemHolder
@onready var item_zoom_panel = $ZoomedItemPanel
@onready var item_name_label = $ZoomedItemPanel/Label2
@onready var item_display_container = $ZoomedItemPanel/ItemDisplayContainer
@onready var close_button = $ZoomedItemPanel/CloseButton
@onready var inventory_instance = $Inventory

var current_zoomed_item: TextureRect = null
var zoom_panel_overlays = []
var overlay_map = {}  # Maps clone overlays to original overlays
var previously_unlocked_items = []
var gem_map = {}  # Tracks gems placed on items: {item_name: {overlay_path: gem_texture}}

# Swipe detection variables
var swipe_start_position := Vector2.ZERO
const SWIPE_THRESHOLD := 100  # Minimum swipe distance in pixels
const SWIPE_BACK_SCENE := "res://scenes/main.tscn"  # Path to your main menu scene

func _ready():
	
	setup_ui()
	initialize_items()
	connect_signals()
	load_gem_placements()

func _input(event: InputEvent):
	# Only process swipe if we're not in zoomed view
	if not item_zoom_panel.visible:
		if event is InputEventScreenTouch:
			if event.pressed:
				swipe_start_position = event.position
			else:
				_check_swipe(event.position)
		elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				swipe_start_position = event.position
			else:
				_check_swipe(event.position)

func _check_swipe(end_position: Vector2):
	var swipe_vector = end_position - swipe_start_position
	if abs(swipe_vector.x) > SWIPE_THRESHOLD and abs(swipe_vector.x) > abs(swipe_vector.y):
		if swipe_vector.x < -0:  # Swiped left
			_return_to_main_menu()

func _return_to_main_menu():
	# Add a smooth fade out transition

	get_tree().change_scene_to_file(SWIPE_BACK_SCENE)

func setup_ui():
	item_zoom_panel.visible = false
	inventory_instance.visible = true

func initialize_items():
	lock_all_items()
	if not "Item9" in Global.unlocked_items:
		Global.unlocked_items.append("Item9")
	previously_unlocked_items = Global.unlocked_items.duplicate()
	Global.save_game() 
	update_unlocked_items()

func connect_signals():
	close_button.pressed.connect(_on_close_pressed)

func load_gem_placements():
	gem_map = Global.load_placed_gems()
	for item_name in gem_map:
		var item = find_item_by_name(item_holder, item_name)
		if item:
			for overlay_path in gem_map[item_name]:
				var overlay = item.get_node_or_null(overlay_path)
				if overlay and _is_black_overlay(overlay):
					overlay.visible = false

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
		if item.get_parent().get_parent() == inventory_instance.rare_gems_list:
			return

		current_zoomed_item = item
		item_name_label.text = item.texture.resource_path.get_file().get_basename() if item.texture else "Unnamed Item"
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

		# Register black overlays in both clone and original
		register_zoom_panel_overlays(clone, item)

		await get_tree().process_frame

		# Scale clone to fit container
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
				# Load and sync visibility for both
				var item_name = current_zoomed_item.name
				var overlay_path = _get_node_path(original_node)
				var is_visible = Global.load_overlay_visibility(item_name, overlay_path)
				clone_node.visible = is_visible
				original_node.visible = is_visible

	var original_children = original_node.get_children() if original_node else []
	var clone_children = clone_node.get_children()

	for i in range(clone_children.size()):
		var orig_child = original_children[i] if i < original_children.size() else null
		register_zoom_panel_overlays(clone_children[i], orig_child)

func _is_black_overlay(node: TextureRect) -> bool:
	return "black" in node.name.to_lower() or \
		   (node.texture and "black_overlay" in node.texture.resource_path.to_lower())

func _get_node_path(node: Node) -> String:
	var path = []
	var current = node
	while current != current_zoomed_item and current != null:
		path.append(str(current.name))
		current = current.get_parent()
	path.reverse()
	return "/".join(path)

func hide_overlay(overlay: TextureRect, gem_texture_path: String = ""):
	overlay.visible = false
	if overlay in overlay_map:
		var original = overlay_map[overlay]
		original.visible = false
		
		var item_name = current_zoomed_item.name
		var overlay_path = _get_node_path(original)
		Global.save_overlay_visibility(item_name, overlay_path, false)
		if gem_texture_path:
			Global.save_placed_gem(item_name, overlay_path, gem_texture_path)

func _on_close_pressed():
	item_zoom_panel.visible = false

	current_zoomed_item = null

func _for_each_item(node: Node, action: Callable):
	for child in node.get_children():
		if child is TextureRect:
			action.call(child)
		elif child.get_child_count() > 0:
			_for_each_item(child, action)

func get_black_overlay_at_position(global_pos: Vector2) -> TextureRect:
	for overlay in zoom_panel_overlays:
		if overlay.get_global_rect().has_point(global_pos):
			return overlay
	return null



func _on_texture_button_pressed() -> void:
	Global.button_press_count += 1
	
	# Show ad only on every 3rd press
	if Global.button_press_count % 3 == 0:
		AdController.show_interstitial()
		await get_tree().create_timer(0.1).timeout
		await AdController.interstitial_closed
	
	# Change scene
	get_tree().change_scene_to_file("res://scenes/main.tscn")
