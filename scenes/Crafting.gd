extends Control

@onready var scroll_container = $Panel/ScrollContainer
@onready var inventory_scene = preload("res://Jewels/Inventory.tscn")  # Make sure this path is correct

var selected_item: TextureRect = null
var selected_item_display: TextureRect = null
var vertical_offset := -150  # Move the selected item up on screen
var inventory_instance: Control = null  # Typed to fix the "cannot infer" error

func _ready():
	# Instance the Inventory scene and add it to the current scene
	inventory_instance = inventory_scene.instantiate()
	add_child(inventory_instance)

	# Set size and anchors to stick to bottom of screen
	inventory_instance.custom_minimum_size = Vector2(get_viewport().size.x, 200)

	inventory_instance.anchor_left = 0
	inventory_instance.anchor_right = 1
	inventory_instance.anchor_top = 1
	inventory_instance.anchor_bottom = 1

	inventory_instance.offset_left = 0
	inventory_instance.offset_right = 0
	inventory_instance.offset_top = -200
	inventory_instance.offset_bottom = 0

	# Hide inventory at start
	inventory_instance.visible = false

	# Connect TextureRects in scroll container
	search_and_connect_texture_rects(scroll_container)

func search_and_connect_texture_rects(parent_node: Node):
	for child in parent_node.get_children():
		if child is TextureRect:
			child.mouse_filter = Control.MOUSE_FILTER_STOP
			child.connect("gui_input", Callable(self, "_on_item_clicked").bind(child))
		elif child is Node:
			search_and_connect_texture_rects(child)

func _on_item_clicked(event: InputEvent, item: TextureRect):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		show_inventory()  # Show inventory when clicking an item

		selected_item = item
		scroll_container.visible = false

		if selected_item_display:
			selected_item_display.queue_free()

		selected_item_display = TextureRect.new()
		selected_item_display.texture = item.texture
		selected_item_display.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		selected_item_display.expand_mode = TextureRect.EXPAND_IGNORE_SIZE

		var display_size = Vector2(400, 400)
		selected_item_display.custom_minimum_size = display_size
		selected_item_display.size = display_size

		var screen_center = (get_viewport_rect().size - display_size) / 2
		selected_item_display.position = Vector2(
			screen_center.x,
			screen_center.y + vertical_offset
		)

		add_child(selected_item_display)
		move_child(selected_item_display, get_child_count() - 1)

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		if selected_item_display:
			selected_item_display.queue_free()
			selected_item_display = null
			scroll_container.visible = true
			inventory_instance.visible = false

func show_inventory():
	inventory_instance.visible = true
