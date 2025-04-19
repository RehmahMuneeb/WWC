extends Node2D

var rock_scene: PackedScene = load("res://scenes/rock.tscn")

var score = 0
var in_danger_zone = false  # Flag to track danger zone status
var reset_zone = false  # Flag for 1000m empty zone after 3000m

@onready var rock_timer = $Rocks/RockTimer
@onready var score_label = $UI/Score
@onready var depth_bar = $UI/ProgressBar
@onready var anim_player = $UI/ProgressBar/AnimationPlayer  # Correct path to AnimationPlayer

func _ready():
	score = 0
	depth_bar.min_value = 0
	depth_bar.max_value = 3000  # Fills from 0–3000, danger zone at 3000–4000
	rock_timer.wait_time = 2.0
	rock_timer.start()

	# Set the fill bar color to red initially
	var fill_stylebox = depth_bar.get("custom_styles/fill")
	if fill_stylebox:
		fill_stylebox.bg_color = Color(1, 0, 0)  # Red color

func _process(delta):
	score += 1
	score_label.text = str(score) + "m"

	var cycle_pos = score % 4000

	# When in the 0 to 3000m range, the bar fills as usual
	if cycle_pos <= 3000:
		depth_bar.value = cycle_pos
		reset_zone = false  # Reset the empty zone flag

		# Exit danger zone
		if in_danger_zone:
			in_danger_zone = false
			if anim_player.is_playing():
				anim_player.stop()
	
			# Reset to red (as the default fill color is red)
			var fill_stylebox = depth_bar.get("custom_styles/fill")
			if fill_stylebox:
				fill_stylebox.modulate = Color(1, 0, 0)

	# After 3000m, set the bar empty until 4000m (1000m empty zone)
	elif cycle_pos > 3000 and cycle_pos <= 4000:
		depth_bar.value = 0
		reset_zone = true  # We're in the 1000m empty zone

		# Enter danger zone
		if not in_danger_zone:
			in_danger_zone = true
			anim_player.play("DangerPulse")  # Start the pulse animation

	# After 4000m, start refilling the bar again (back to 0–3000 range)
	else:
		depth_bar.value = cycle_pos - 3000  # Reset the value to begin filling after 4000m
		reset_zone = false

	update_rock_spawn_speed()

func update_rock_spawn_speed():
	var depth_in_cycle = score % 6000
	if depth_in_cycle >= 3000 and depth_in_cycle < 4000:
		if rock_timer.wait_time != 0.5:
			rock_timer.wait_time = 0.5
			rock_timer.start()
	else:
		if rock_timer.wait_time != 3.0:
			rock_timer.wait_time = 3.0
			rock_timer.start()

func _on_rock_timer_timeout():
	var rock = rock_scene.instantiate()
	$Rocks.add_child(rock)
