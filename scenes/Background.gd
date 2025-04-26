extends Node2D

@onready var air_effect = $AirEffect
@onready var normal_bg = $WallImg  # Normal background
@onready var lava_bg = $WallImg2    # Single lava background for all danger zones
@onready var ice_bg = $WallImg5      # Ice background
@onready var warning_label = $WarningLabel
@onready var jewel_spawner = $"../JewelSpawner"

var main_script: Node
var score = 0
var warning_shown = false
var last_warning_zone = -1

func _ready():
	main_script = get_parent()  # Main script is parent node
	air_effect.visible = false
	air_effect.emitting = false
	normal_bg.visible = true
	lava_bg.visible = false
	ice_bg.visible = false
	warning_label.visible = false
	warning_label.modulate.a = 0.0

func _process(delta):
	score = main_script.score  # Sync score with main script
	var depth = score % 12000
	
	# Check for upcoming danger zones (100m before)
	_check_upcoming_danger_zones(depth)
	
	# Check current zone and update background
	_update_background_based_on_zone(depth)
	
	# Air effect: 2000-2999
	if depth >= 2000 and depth < 3000:
		if not air_effect.emitting:
			air_effect.visible = true
			air_effect.emitting = true
	else:
		if air_effect.emitting:
			air_effect.visible = false
			air_effect.emitting = false

func _check_upcoming_danger_zones(depth: int):
	# Check all zones for upcoming danger (100m before)
	for i in range(main_script.zone_depths.size()):
		var zone_start = main_script.zone_depths[i]
		var warning_start = zone_start - 100
		
		# Check if we're in the warning zone but haven't shown the warning yet
		if depth >= warning_start and depth < zone_start and last_warning_zone != i:
			show_warning("DANGER\nAHEAD!")
			last_warning_zone = i
			break
		# Reset warning tracking when we pass the zone
		elif depth >= zone_start and last_warning_zone == i:
			last_warning_zone = -1

func _update_background_based_on_zone(depth: int):
	var in_danger_zone = false
	
	# Check if we're in any danger zone
	for i in range(main_script.zone_depths.size()):
		if depth >= main_script.zone_depths[i] and depth < main_script.zone_depths[i] + main_script.zone_width:
			in_danger_zone = true
			break
	
	# Ice zone (special case)
	if depth >= 1000 and depth < 2000:
		_set_background_zone(2)  # Ice
		jewel_spawner.set_lava_active(false)
	elif in_danger_zone:
		_set_background_zone(1)  # Lava (all danger zones use same background)
		jewel_spawner.set_lava_active(true)
	else:
		_set_background_zone(0)  # Normal
		jewel_spawner.set_lava_active(false)

func _set_background_zone(zone: int):
	# 0 = Normal, 1 = Lava, 2 = Ice
	normal_bg.visible = (zone == 0)
	lava_bg.visible = (zone == 1)
	ice_bg.visible = (zone == 2)

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
