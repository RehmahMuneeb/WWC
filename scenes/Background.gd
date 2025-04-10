extends Node2D

@onready var air_effect = $AirEffect
@onready var main_bg = $WallImg     # Normal background
@onready var lava_bg = $WallImg2     # Lava background

var score = 0

func _ready():
	air_effect.visible = false
	air_effect.emitting = false
	main_bg.visible = true
	lava_bg.visible = false

func _process(delta):
	score += 1  # Update this based on your game logic

	var depth_in_cycle = score % 6000

	# --- Handle Air Effect (2000–2999 in every 6000 cycle) ---
	if depth_in_cycle >= 2000 and depth_in_cycle < 3000:
		if not air_effect.emitting:
			air_effect.visible = true
			air_effect.emitting = true
	else:
		if air_effect.emitting:
			air_effect.visible = false
			air_effect.emitting = false

	# --- Handle Lava Background (5000–5999 in every 6000 cycle) ---
	if depth_in_cycle >= 5000 and depth_in_cycle < 6000:
		lava_bg.visible = true
		main_bg.visible = false
	else:
		lava_bg.visible = false
		main_bg.visible = true
