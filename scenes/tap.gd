extends Label2

func _ready():
	set_pivot_to_center()
	zoom()

func set_pivot_to_center():
	# Wait one frame to ensure size is correct
	await get_tree().process_frame
	pivot_offset = size / 2
	position -= pivot_offset  # Shift position so center stays visually fixed

func zoom():
	var tween = get_tree().create_tween()
	tween.set_loops()
	tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
