extends Sprite2D

var dragging := false
var last_touch_position := Vector2()
var min_y := 0.0
var max_y := 0.0

func _ready():
	centered = false  # Important for position alignment

	var screen_height = get_viewport_rect().size.y
	var texture_height = texture.get_height()

	min_y = screen_height - texture_height  # top-most scroll
	max_y = 0  # bottom-most scroll

	position.y = min_y  # ✅ start from bottom of texture, showing bottom part first

func _unhandled_input(event):
	if event is InputEventScreenTouch:
		if event.pressed:
			dragging = true
			last_touch_position = event.position
		else:
			dragging = false

	elif event is InputEventScreenDrag and dragging:
		var delta = event.position - last_touch_position
		last_touch_position = event.position

		position.y += delta.y
		position.y = clamp(position.y, min_y, max_y)


func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")
