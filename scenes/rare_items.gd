extends Control

@onready var inventory_panel = $PanelContainer
@onready var scroll_container = $Panel/ScrollContainer
var selected_item: TextureRect = null  # The currently selected item

func _ready():
	# Hide inventory panel initially
	inventory_panel.visible = false
	
	# Start the recursive search for TextureRect nodes
	search_and_connect_texture_rects(scroll_container)

# Recursive function to find all TextureRect nodes inside ScrollContainer
func search_and_connect_texture_rects(parent_node: Node):
	for child in parent_node.get_children():
		if child is TextureRect:
			child.mouse_filter = Control.MOUSE_FILTER_STOP  # Enable input detection
			child.gui_input.connect(_on_item_clicked.bind(child))  # Connect click event
		elif child is Node:  # If the child is a container or group node
			search_and_connect_texture_rects(child)  # Recurse into its children

# Function to handle item clicks
func _on_item_clicked(event: InputEvent, item: TextureRect):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		# Show inventory panel and set the selected item
		selected_item = item
		inventory_panel.visible = true

		# Hide all other items except the selected one
		for child in scroll_container.get_children():
			if child is Node:
				for item_container in child.get_children():
					if item_container is TextureRect:
						item_container.visible = (item_container == selected_item)

		print("Item clicked:", item.name)
