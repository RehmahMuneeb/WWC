extends Control

var bucket_icon: TextureRect
var chest_icon: TextureRect
var chest_progress_bar: ProgressBar
var progress_label: Label
var gem_score_label: Label
var multiply_label: Label  # Added for showing x3 score

const BASE_COINS_TO_UNLOCK := 1000
var chest_unlocked := false
var current_chest := 1
var current_target := BASE_COINS_TO_UNLOCK
var animation_speed := 1.0
const FAST_SPEED := 0.2
var speed_increased := false

var current_session_score := 0
var skip_animation := false
var animation_running := false

func _ready():
	current_session_score = 0

	bucket_icon = $"Bucket Capacity2/Bucket"
	chest_icon = $"Bucket Capacity2/Chest"
	chest_progress_bar = $"Bucket Capacity2/ProgressBar"
	progress_label = chest_progress_bar.get_node("ProgressLabel")
	gem_score_label = $"Bucket Capacity2/GemScoreLabel"
	multiply_label = $"AD BAR2/Multiply"  # Get reference to Multiply label

	# Initialize UI
	gem_score_label.text = "+0"
	multiply_label.text = "x3: 0"
	chest_progress_bar.max_value = current_target
	update_chest_progress()

	await animate_gems_with_float_motion()

func _input(event):
	if not speed_increased and ((event is InputEventScreenTouch and event.pressed) or 
	   (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT)):
		speed_increased = true
		animation_speed = FAST_SPEED
		print("Animation speed increased permanently")

func animate_gems_with_float_motion() -> void:
	animation_running = true
	var score_per_gem := 10

	for gem_texture in Global.collected_gems:
		if gem_texture == null:
			continue

		if skip_animation:
			current_session_score += score_per_gem
			Global.score += score_per_gem
			continue

		var gem = TextureRect.new()
		gem.texture = gem_texture
		gem.expand = true
		gem.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		gem.custom_minimum_size = Vector2(64, 64)
		add_child(gem)

		var start_pos = bucket_icon.get_global_position()
		var end_pos = chest_icon.get_global_position()
		gem.global_position = start_pos

		var duration := 1.0 * animation_speed
		var elapsed := 0.0
		var amplitude := 40
		var frequency := 3.0

		while elapsed < duration:
			if skip_animation:
				break
			var t := elapsed / duration
			var linear = start_pos.lerp(end_pos, t)
			var offset = Vector2(0, sin(t * PI * frequency) * -amplitude)
			gem.global_position = linear + offset
			await get_tree().process_frame
			elapsed += get_process_delta_time()

		gem.queue_free()

		current_session_score += score_per_gem
		Global.score += score_per_gem
		gem_score_label.text = "+%d" % current_session_score
		multiply_label.text = "x3: %d" % (current_session_score * 3)

		update_chest_progress()

		if not skip_animation:
			show_score_popup("+%d" % score_per_gem, chest_icon.get_global_position())
			await get_tree().create_timer(0.2 * animation_speed).timeout

	animation_running = false

func update_chest_progress():
	chest_progress_bar.value = Global.score
	progress_label.text = "%d / %d" % [Global.score, current_target]

	if not chest_unlocked and Global.score >= current_target:
		chest_unlocked = true
		unlock_chest()

func unlock_chest():
	print("Chest %d Unlocked!" % current_chest)
	Global.score = 0
	current_session_score = 0
	gem_score_label.text = "+0"
	multiply_label.text = "x3: 0"

	if current_chest < 30:
		current_chest += 1
		current_target = BASE_COINS_TO_UNLOCK * current_chest
		chest_unlocked = false
		chest_progress_bar.max_value = current_target
		progress_label.text = "%d / %d" % [Global.score, current_target]
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
	skip_animation = true

	while animation_running:
		await get_tree().process_frame

	Global.collected_gems = []
	current_session_score = 0
	get_tree().change_scene_to_file("res://scenes/level.tscn")

func _on_main_menu_pressed() -> void:
	skip_animation = true

	while animation_running:
		await get_tree().process_frame

	Global.collected_gems = []
	current_session_score = 0
	get_tree().change_scene_to_file("res://scenes/main.tscn")
