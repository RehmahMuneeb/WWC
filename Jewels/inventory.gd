extends Control

@onready var rare_gems_list := $TextureRect/ScrollContainer/VBoxContainer
var drag_layer: CanvasLayer
var dragging_icon: TextureRect = null
var original_position: Vector2 = Vector2.ZERO
var original_parent: Node = null
var drag_offset: Vector2 = Vector2.ZERO
var is_dragging := false

func _ready():
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
			start_drag(icon, event.global_position)
		elif is_dragging:
			handle_drop(event.global_position)
	elif event is InputEventMouseMotion and is_dragging:
		dragging_icon.global_position = event.global_position + drag_offset

func start_drag(icon: TextureRect, mouse_pos: Vector2):
	is_dragging = true
	dragging_icon = icon
	original_parent = icon.get_parent()
	original_position = icon.global_position
	drag_offset = icon.global_position - mouse_pos
	
	original_parent.remove_child(icon)
	drag_layer.add_child(icon)
	icon.global_position = original_position

func handle_drop(drop_pos: Vector2):
	var main = get_parent()
	
	if not dragging_icon:
		reset_drag_state()
		return
	
	# Extract the gem name (assumes texture resource path as identifier)
	var dragged_gem_name = dragging_icon.texture.resource_path.get_file().get_basename().to_lower()
	
	if main.item_zoom_panel.visible:
		var black_overlay = main.get_black_overlay_at_position(drop_pos)
		if black_overlay:
			var overlay_name = black_overlay.name.to_lower()
			
			# Check if gem fits this overlay slot
			if Global.gem_slot_map.has(overlay_name) and Global.gem_slot_map[overlay_name].to_lower() == dragged_gem_name:
				# Hide black overlay on zoom item to reveal gem
				black_overlay.visible = false
				
				# Also hide corresponding black overlay on actual item (sync)
				if main.overlay_map.has(black_overlay):
					var original_overlay = main.overlay_map[black_overlay]
					if is_instance_valid(original_overlay):
						original_overlay.visible = false
				
				# Remove gem icon from inventory UI
				dragging_icon.queue_free()
				reset_drag_state()
				return
			
			# If mismatch, return gem
			reset_drag_state()
			return
	
	# If not dropped on zoom panel overlay, return gem to inventory
	reset_drag_state()

func reset_drag_state():
	if is_dragging and dragging_icon:
		if dragging_icon.get_parent() == drag_layer:
			drag_layer.remove_child(dragging_icon)
		if original_parent and not dragging_icon.is_queued_for_deletion():
			original_parent.add_child(dragging_icon)
			dragging_icon.global_position = original_position
	is_dragging = false
	dragging_icon = null

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed and is_dragging:
		handle_drop(event.global_position)
	elif event is InputEventMouseMotion and is_dragging:
		dragging_icon.global_position = event.global_position + drag_offset
