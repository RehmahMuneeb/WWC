extends Sprite2D

var target_speed = 0.9
var min_speed = 0.3
var scroll_speed = 0.3
var speed_increment = 0.001  # Adjust for how fast you want it to increase

func _process(delta):
	if scroll_speed < target_speed:
		scroll_speed = min(scroll_speed + speed_increment * delta, target_speed)
		material.set_shader_parameter("scroll_speed", scroll_speed)
