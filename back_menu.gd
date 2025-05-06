extends Control

var bucket_icon: TextureRect
var chest_icon: TextureRect
var chest_progress_bar: ProgressBar
var progress_label: Label

const BASE_COINS_TO_UNLOCK := 1000
var chest_unlocked := false
var current_chest := 1
var current_target := BASE_COINS_TO_UNLOCK
var animation_speed := 1.0  # Normal speed by default
const FAST_SPEED := 0.2     # 5x faster speed
var speed_increased := false # Track if we've sped up

func _ready():
	# Set initial score label
	$"Bucket Capacity2/ScoreLabel".text = "Score: %d" % Global.score

	bucket_icon = $"Bucket Capacity2/Bucket"
	chest_icon = $"AD BAR2/Chest"
	chest_progress_bar = $"Bucket Capacity2/ProgressBar"
	progress_label = chest_progress_bar.get_node("ProgressLabel")

	# Initialize progress bar
	chest_progress_bar.max_value = current_target
	update_chest_progress()

	# Start animated gem transfer
	await animate_gems_with_float_motion()

func _input(event):
	# Speed up permanently on first tap
	if not speed_increased and ((event is InputEventScreenTouch and event.pressed) or 
	   (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT)):
		speed_increased = true
		animation_speed = FAST_SPEED
		print("Animation speed increased permanently")

func animate_gems_with_float_motion() -> void:
	var score_per_gem := 10

	for gem_texture in Global.collected_gems:
		if gem_texture == null:
			continue

		var gem = TextureRect.new()
		gem.texture = gem_texture
		gem.expand = true
		gem.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		gem.custom_minimum_size = Vector2(64, 64)
		add_child(gem)

		# Start and end positions
		var start_pos = bucket_icon.get_global_position()
		var end_pos = chest_icon.get_global_position()
		gem.global_position = start_pos

		# Animate gem floaty movement
		var duration := 1.0 * animation_speed
		var elapsed := 0.0
		var amplitude := 40
		var frequency := 3.0

		while elapsed < duration:
			var t := elapsed / duration
			var linear = start_pos.lerp(end_pos, t)
			var offset = Vector2(0, sin(t * PI * frequency) * -amplitude)
			gem.global_position = linear + offset
			await get_tree().process_frame
			elapsed += get_process_delta_time()

		# Remove gem
		gem.queue_free()

		# Update score
		Global.score += score_per_gem
		$"Bucket Capacity2/ScoreLabel".text = "Score: %d" % Global.score
		update_chest_progress()

		# Show floating "+X" popup
		show_score_popup("+%d" % score_per_gem, chest_icon.get_global_position())

		# Delay between gems (affected by speed)
		await get_tree().create_timer(0.2 * animation_speed).timeout

func update_chest_progress():
	chest_progress_bar.value = Global.score
	progress_label.text = "%d / %d" % [Global.score, current_target]

	if not chest_unlocked and Global.score >= current_target:
		chest_unlocked = true
		unlock_chest()

func unlock_chest():
	print("Chest %d Unlocked!" % current_chest)
	# Add your unlock effects here
	
	if current_chest < 30:
		current_chest += 1
		current_target = BASE_COINS_TO_UNLOCK * current_chest
		chest_unlocked = false
		chest_progress_bar.max_value = current_target
		chest_progress_bar.value = Global.score
		update_chest_progress()
	else:
		print("All chests unlocked!")

func show_score_popup(text: String, position: Vector2) -> void:
	var label = Label.new()
	label.text = text
	label.add_theme_color_override("font_color", Color(1, 1, 0))
	label.add_theme_font_size_override("font_size", 32)
	label.position = position - Vector2(0, 30)
	add_child(label)

	var tween = create_tween()
	tween.set_speed_scale(1.0 / animation_speed)
	tween.tween_property(label, "modulate:a", 0.0, 1.0)
	tween.tween_property(label, "position:y", label.position.y - 30, 1.0)
	tween.tween_callback(label.queue_free)

func _on_play_again_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/level.tscn")

func _on_main_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")
