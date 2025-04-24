extends Node2D

@onready var air_effect = $AirEffect
@onready var main_bg = $WallImg         # Normal background
@onready var lava_bg = $WallImg2        # Lava 1 background
@onready var lava_bg2 = $WallImg3       # Lava 2 background
@onready var lava_bg3 = $WallImg4       # Lava 3 background
@onready var ice_bg =   $WallImg5   # Ice background
@onready var warning_label = $WarningLabel
@onready var jewel_spawner = $"../JewelSpawner"

var score = 0
var warning_shown = false

func _ready():
	air_effect.visible = false
	air_effect.emitting = false
	main_bg.visible = true
	lava_bg.visible = false
	lava_bg2.visible = false
	lava_bg3.visible = false
	ice_bg.visible = false
	warning_label.visible = false
	warning_label.modulate.a = 0.0

func _process(delta):
	score += 1
	var depth = score % 12000

	# Air effect: 2000–2999
	if depth >= 2000 and depth < 3000:
		if not air_effect.emitting:
			air_effect.visible = true
			air_effect.emitting = true
	else:
		if air_effect.emitting:
			air_effect.visible = false
			air_effect.emitting = false

	# Lava 1: 3000–3999
	if depth >= 3000 and depth < 4000:
		_set_lava_zone(1)
		jewel_spawner.set_lava_active(true)
	# Lava 2: 7000–7999
	elif depth >= 7000 and depth < 8000:
		_set_lava_zone(2)
		jewel_spawner.set_lava_active(true)
	# Lava 3: 11000–11999
	elif depth >= 11000 and depth < 12000:
		_set_lava_zone(3)
		jewel_spawner.set_lava_active(true)
	# Ice: 5000–5999
	elif depth >= 1000 and depth < 2000:
		_set_lava_zone(4)
		jewel_spawner.set_lava_active(false)  # Or true if ice affects spawning
	else:
		_set_lava_zone(0)
		jewel_spawner.set_lava_active(false)

	# Warning zones before lava/ice
	if (depth >= 2900 and depth < 3000) or (depth >= 4900 and depth < 5000) or (depth >= 5900 and depth < 6000) or (depth >= 8900 and depth < 9000):
		if not warning_shown:
			show_warning("DANGER\nAHEAD!")
			warning_shown = true
	else:
		warning_shown = false

func _set_lava_zone(zone: int):
	main_bg.visible = (zone == 0)
	lava_bg.visible = (zone == 1)
	lava_bg2.visible = (zone == 2)
	lava_bg3.visible = (zone == 3)
	ice_bg.visible = (zone == 4)

func show_warning(text: String):
	warning_label.text = text
	warning_label.visible = true
	warning_label.modulate.a = 0.0
	warning_label.scale = Vector2(1, 1)

	var tween = create_tween()
	tween.tween_property(warning_label, "modulate:a", 1.0, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_interval(1.5)
	tween.tween_property(warning_label, "modulate:a", 0.0, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_callback(Callable(warning_label, "hide"))
