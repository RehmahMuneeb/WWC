extends Node2D

@onready var normal_bg = $WallImg
@onready var lava_bg = $WallImg2
@onready var ice_bg = $WallImg5
@onready var warning_label = $WarningLabel
@onready var jewel_spawner = $"../JewelSpawner"

var main_script: Node
var score = 0
var warning_shown = false
var last_warning_zone = -1

# Shake effect
var shake_timer = 0.0
var shake_duration = 0.6
var shake_strength = 11.0
var last_zone = -1
var original_position = Vector2.ZERO
var original_rotation = 0.0
var shaking = false  # Flag to check if shaking is in progress
var background_changed = false  # Flag to track if the background has changed

func _ready():
	main_script = get_parent()

	normal_bg.visible = true
	lava_bg.visible = false
	ice_bg.visible = false
	warning_label.visible = false
	warning_label.modulate.a = 0.0

	original_position = position
	original_rotation = rotation

func _process(delta):
	score = main_script.score
	var depth = score % 11000

	_check_upcoming_danger_zones(depth)
	_update_background_based_on_zone(depth)

	# Apply shake only after the background has changed
	if background_changed and shake_timer > 0:
		shake_timer -= delta
		var offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * shake_strength
		var angle = deg_to_rad(randf_range(-3, 3))  # Small rotation shake
		position = original_position + offset
		rotation = original_rotation + angle
		shaking = true
	else:
		if shaking:
			# Once shaking ends, reset position and apply the new background
			_set_background_zone(last_zone)
			shaking = false
			background_changed = false
		position = original_position
		rotation = original_rotation

func _check_upcoming_danger_zones(depth: int):
	for i in range(main_script.zone_depths.size()):
		var zone_start = main_script.zone_depths[i]
		var warning_start = zone_start - 100

		if depth >= warning_start and depth < zone_start and last_warning_zone != i:
			show_warning("DANGER\nAHEAD!")
			last_warning_zone = i
			break
		elif depth >= zone_start + main_script.zone_width and last_warning_zone == i:
			last_warning_zone = -1

func _update_background_based_on_zone(depth: int):
	var in_danger_zone = false

	for i in range(main_script.zone_depths.size()):
		if depth >= main_script.zone_depths[i] and depth < main_script.zone_depths[i] + main_script.zone_width:
			in_danger_zone = true
			break

	var in_ice_zone = depth >= 10000 and depth < 11000

	if in_ice_zone:
		if last_zone != 2:  # Only trigger if changing to ice zone
			_trigger_background_change(2, false)  # No shake for ice
		jewel_spawner.set_lava_active(false)
	elif in_danger_zone:
		if last_zone != 1:  # Only trigger if changing to lava zone
			_trigger_background_change(1, true)  # Shake for lava
		jewel_spawner.set_lava_active(true)
	else:
		if last_zone != 0:  # Only trigger if changing to normal zone
			_trigger_background_change(0, false)  # No shake for normal
		jewel_spawner.set_lava_active(false)

func _trigger_background_change(zone: int, should_shake: bool):
	# Trigger shake only if should_shake is true (for lava zone)
	if zone != last_zone:
		if should_shake:
			shake_timer = shake_duration
		last_zone = zone
		background_changed = true  # Mark that the background has changed
		# Immediately change background if no shake needed
		if not should_shake:
			_set_background_zone(zone)

func _set_background_zone(zone: int):
	# Apply the new background
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
