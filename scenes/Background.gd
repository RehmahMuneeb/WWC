extends Node2D

@onready var air_effect = $AirEffect  # Adjust the path as necessary
var score = 0  # Depth in meters
var activation_depth = 1000
var deactivation_depth = activation_depth + 1000
var effect_active = false

func _ready():
	air_effect.emitting = false
	air_effect.visible = false

func _process(delta):
	score += 1  # Update depth; adjust this logic as per your game's mechanics

	if score >= activation_depth and score < deactivation_depth:
		if not effect_active:
			air_effect.visible = true
			air_effect.emitting = true
			effect_active = true
	elif score >= deactivation_depth:
		if effect_active:
			air_effect.emitting = false
			air_effect.visible = false
			effect_active = false
			# Set the next activation depth after a 1000m gap
			activation_depth = deactivation_depth + 1000
			deactivation_depth = activation_depth + 1000
