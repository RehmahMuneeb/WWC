extends Area2D

var speed: float = 400  # Initial speed of the rock

func _ready():
	var rng := RandomNumberGenerator.new()
	
	#random width and height
	var width = get_viewport().get_visible_rect().size[0]
	var random_x = rng.randi_range(0, width)
	var random_y = rng.randi_range(-150, -50)
	self.position = Vector2(random_x, random_y)

func _process(delta):
	 # Gradually increase the speed over time
	speed += 100 * delta 
		
	self.position += Vector2(0, 1.0) * speed * delta 
	
