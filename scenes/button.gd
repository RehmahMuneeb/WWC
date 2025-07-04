extends Button

var base_scale := Vector2.ONE
var pulse_amount := 0.1      # How much to zoom
var pulse_speed := 0.6   # Zoom in/out cycles per second
var time := 0.0
var initialized := false

func _ready():
	# Delay pivot setup so button size is fully loaded
	await get_tree().process_frame
	set_pivot_offset(size / 2)
	initialized = true

func _process(delta):
	if not initialized:
		return

	time += delta
	var scale_factor = 1.0 + sin(time * TAU * pulse_speed) * pulse_amount
	scale = base_scale * scale_factor
