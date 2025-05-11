extends Control

@onready var item_holder = $Panel/ItemHolder
@onready var item_zoom_panel = $ZoomedItemPanel
@onready var item_name_label = $ZoomedItemPanel/Label
@onready var item_texture = $ZoomedItemPanel/TextureRect
@onready var close_button = $ZoomedItemPanel/CloseButton
@onready var inventory_instance = $ZoomedItemPanel/Inventory  # Inventory is already a child node

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
		item_texture.texture = item.texture
		item_name_label.text = item.name if item.name != "" else "Unnamed Item"
		item_zoom_panel.visible = true
		inventory_instance.visible = true

func _on_close_pressed():
	item_zoom_panel.visible = false
	inventory_instance.visible = false
