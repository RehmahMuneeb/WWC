extends Control

@onready var inventory_panel = $PanelContainer
@onready var scroll_container = $Panel/ScrollContainer
var selected_item: TextureRect = null
var selected_item_display: TextureRect = null
var vertical_offset = -150  # Adjust this value to move the item up (negative) or down (positive)

func _ready():
	inventory_panel.visible = false
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
		# Set up selection
		selected_item = item
		inventory_panel.visible = true
		scroll_container.visible = false
		
		# Clear previous selection
		if selected_item_display:
			selected_item_display.queue_free()
		
		# Create new display
		selected_item_display = TextureRect.new()
		selected_item_display.texture = item.texture
		selected_item_display.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		selected_item_display.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		
		# Set size
		var display_size = Vector2(400, 400)  # Adjust this as needed
		selected_item_display.custom_minimum_size = display_size
		selected_item_display.size = display_size
		
		# Calculate centered position with vertical offset
		var screen_center = (get_viewport_rect().size - display_size) / 2
		selected_item_display.position = Vector2(
			screen_center.x,  # Keep horizontal center
			screen_center.y + vertical_offset  # Apply vertical offset
		)
		
		add_child(selected_item_display)
		move_child(selected_item_display, get_child_count() - 1)

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		if selected_item_display:
			selected_item_display.queue_free()
			selected_item_display = null
			scroll_container.visible = true
			inventory_panel.visible = false
