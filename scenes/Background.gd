extends Node2D

@onready var air_effect = $AirEffect
@onready var main_bg = $WallImg     # Normal background
@onready var lava_bg = $WallImg2    # Lava background
@onready var warning_label = $WarningLabel
@onready var jewel_spawner = $"../JewelSpawner"  # Adjust path if necessary

var score = 0
var warning_shown = false

func _ready():
	air_effect.visible = false
	air_effect.emitting = false
	main_bg.visible = true
	lava_bg.visible = false
	warning_label.visible = false
	warning_label.modulate.a = 0.0

func _process(delta):
	score += 1
	var depth_in_cycle = score % 6000

	# --- Air Effect (2000–2999) ---
	if depth_in_cycle >= 2000 and depth_in_cycle < 3000:
		if not air_effect.emitting:
			air_effect.visible = true
			air_effect.emitting = true
	else:
		if air_effect.emitting:
			air_effect.visible = false
			air_effect.emitting = false

	# --- Lava Background (5000–5999) ---
	if depth_in_cycle >= 1000 and depth_in_cycle < 2000:
		lava_bg.visible = true
		main_bg.visible = false
		# Disable jewel spawner when lava is active
		jewel_spawner.set_lava_active(true)
	else:
		lava_bg.visible = false
		main_bg.visible = true
		# Enable jewel spawner when lava is not active
		jewel_spawner.set_lava_active(false)

	# --- Show Warning Before Lava (4900–5000) ---
	if depth_in_cycle >= 950 and depth_in_cycle < 1000:
		if not warning_shown:
			show_warning("DANGER\nAHEAD!")
			warning_shown = true
	else:
		warning_shown = false

func show_warning(text: String):
	warning_label.text = text
	warning_label.visible = true
	warning_label.modulate.a = 0.0
	warning_label.scale = Vector2(1, 1)  # Ensure it's at full size
	
	var tween = create_tween()
	tween.tween_property(warning_label, "modulate:a", 1.0, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_interval(1.5)  # How long it stays visible
	tween.tween_property(warning_label, "modulate:a", 0.0, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_callback(Callable(warning_label, "hide"))
