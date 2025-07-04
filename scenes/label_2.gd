extends Label

@onready var tween = create_tween()

func _ready():
	pivot_offset = size / 2  # Zoom from center
	scale = Vector2.ONE
	zoom_in_out()

func zoom_in_out():
	tween.set_loops()  # Loop forever
	tween.tween_property(self, "scale", Vector2(1.1, 1.1), 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
