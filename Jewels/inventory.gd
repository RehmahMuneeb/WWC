extends Control

@onready var rare_gems_list := $TextureRect/ScrollContainer/VBoxContainer
var drag_layer: CanvasLayer

var dragging_icon: TextureRect = null
var original_position: Vector2 = Vector2.ZERO
var original_parent: Node = null
var drag_offset: Vector2 = Vector2.ZERO
var is_dragging := false

func _ready():
	# Create a dedicated drag layer
	drag_layer = CanvasLayer.new()
	drag_layer.layer = 100
	get_tree().root.add_child(drag_layer)
	
	display_rare_gems()

func display_rare_gems():
	for child in rare_gems_list.get_children():
		child.queue_free()

	for gem_texture in Global.rare_gems:
		if gem_texture == null:
			continue
			
		var icon = TextureRect.new()
		icon.texture = gem_texture
		icon.expand = true
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = Vector2(64, 64)
		icon.mouse_filter = Control.MOUSE_FILTER_STOP
		rare_gems_list.add_child(icon)
		
		icon.connect("gui_input", Callable(self, "_on_gem_input").bind(icon))

func _on_gem_input(event: InputEvent, icon: TextureRect):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			# Start drag
			is_dragging = true
			dragging_icon = icon
			original_parent = icon.get_parent()
			original_position = icon.global_position
			drag_offset = icon.global_position - event.global_position
			
			# Reparent to drag layer
			original_parent.remove_child(icon)
			drag_layer.add_child(icon)
			icon.global_position = original_position
			
			
			get_viewport().set_input_as_handled()
		elif is_dragging:  # Only handle release if we were dragging
			# End drag
			is_dragging = false
			drag_layer.remove_child(icon)
			original_parent.add_child(icon)
			icon.global_position = original_position
			icon.modulate = Color.WHITE
			dragging_icon = null
			
			get_viewport().set_input_as_handled()
	
	elif event is InputEventMouseMotion and is_dragging:
		dragging_icon.global_position = event.global_position + drag_offset
		get_viewport().set_input_as_handled()

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed and is_dragging:
		# Handle mouse release if it occurs outside the original control
		is_dragging = false
		drag_layer.remove_child(dragging_icon)
		original_parent.add_child(dragging_icon)
		dragging_icon.global_position = original_position
		dragging_icon.modulate = Color.WHITE
		dragging_icon = null
		
	elif event is InputEventMouseMotion and is_dragging:
		dragging_icon.global_position = event.global_position + drag_offset
		get_viewport().set_input_as_handled()
