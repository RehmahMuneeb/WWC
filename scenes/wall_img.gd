extends Sprite2D

var scroll_offset := 0.0
var target_speed := 0.9
var min_speed := 0.3
var scroll_speed := 0.3
var speed_increment := 0.001  # Adjust how fast it accelerates

@onready var mat := material

func _process(delta):
	if scroll_speed < target_speed:
		scroll_speed = min(scroll_speed + speed_increment * delta, target_speed)

	scroll_offset += scroll_speed * delta
	mat.set_shader_parameter("scroll_offset", scroll_offset)
