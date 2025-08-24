extends TextureRect

func _ready():
	_pulse()

func _pulse(phase: float = 0.0):
	var tween = create_tween().set_loops().set_process_mode(Tween.TWEEN_PROCESS_IDLE)
	tween.tween_method(func(p): modulate = Color(1.0, 1.0 - 0.2 * sin(p), 1.0 - 0.3 * sin(p), 1.0), 0.0, 2.0 * PI, 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
