extends Control

# UI elements
var bucket_icon: TextureRect
var chest_icon: TextureRect
var chest_progress_bar: ProgressBar
var progress_label: Label
var gem_score_label: Label
var multiply_label: Label

# Constants and variables
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
var total_multiplied_score := 0

var is_exiting := false

# Reward panel UI elements
var reward_panel: Control
var reward_label: Label
var reward_button: Button
var reward_icon: TextureRect

func _ready():
	# Initialize UI elements
	current_session_score = 0
	is_exiting = false

	bucket_icon = $"Bucket Capacity2/Bucket"
	chest_icon = $"Bucket Capacity2/Chest"
	chest_progress_bar = $"Bucket Capacity2/ProgressBar"
	progress_label = chest_progress_bar.get_node("ProgressLabel")
	gem_score_label = $"Bucket Capacity2/GemScoreLabel"
	multiply_label = $"AD BAR2/Multiply"

	# Initialize progress and score labels
	gem_score_label.text = "+0"
	multiply_label.text = "x3: 0"
	chest_progress_bar.max_value = current_target
	chest_progress_bar.value = 0
	update_chest_progress()

	# Initialize reward panel
	reward_panel = $RewardPanel
	reward_label = reward_panel.get_node("RewardLabel")
	reward_button = reward_panel.get_node("ClaimButton")
	reward_icon = reward_panel.get_node("GemIcon")  # Ensure GemIcon exists
	reward_panel.hide()
	reward_button.pressed.connect(_on_claim_reward_pressed)

	await animate_gems_with_float_motion()

func _input(event):
	# Speed increase on first touch/click
	if not speed_increased and ((event is InputEventScreenTouch and event.pressed) or 
	   (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT)):
		speed_increased = true
		animation_speed = FAST_SPEED
		print("Animation speed increased permanently")

func animate_gems_with_float_motion() -> void:
	animation_running = true
	var score_per_gem := 1000

	# Animate each gem collected in Global.collected_gems
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

		# Animate gem motion
		while elapsed < duration:
			if skip_animation:
				break
			var t := elapsed / duration
			var linear = start_pos.lerp(end_pos, t)
			var offset = Vector2(0, sin(t * PI * frequency) * -amplitude)
			gem.global_position = linear + offset
			await get_tree().process_frame
			elapsed += get_process_delta_time()

		# Free gem after animation
		gem.queue_free()

		current_session_score += score_per_gem
		Global.score += score_per_gem
		total_multiplied_score += score_per_gem * 3
		gem_score_label.text = "+%d" % current_session_score
		multiply_label.text = "x3: %d" % total_multiplied_score

		update_chest_progress()

		if not skip_animation:
			show_score_popup("+%d" % score_per_gem, chest_icon.get_global_position())
			await get_tree().create_timer(0.2 * animation_speed).timeout

	animation_running = false

func update_chest_progress():
	# Update chest progress bar
	chest_progress_bar.value = Global.score
	progress_label.text = "%d    /    %d" % [Global.score, current_target]

	# Unlock chest when target is reached
	if not chest_unlocked and Global.score >= current_target:
		chest_unlocked = true
		unlock_chest()

func unlock_chest():
	# Handle chest unlocking logic
	print("Chest %d Unlocked!" % current_chest)

	Global.score = 0
	current_session_score = 0
	chest_unlocked = true

	show_reward_panel()

	# Update next chest target or max chests
	if current_chest < 30:
		current_chest += 1
		current_target = BASE_COINS_TO_UNLOCK * current_chest
	else:
		print("All chests unlocked!")

	chest_progress_bar.max_value = current_target
	chest_progress_bar.value = 0
	progress_label.text = "0    /    %d" % current_target
	gem_score_label.text = "+0"

	chest_unlocked = false

func show_score_popup(text: String, position: Vector2) -> void:
	# Show score pop-up animation
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

func show_reward_panel():
	# Show reward panel after unlocking chest
	if is_exiting or reward_panel == null:
		return

	reward_panel.show()
	reward_label.text = "YOU RECEIVED A RARE GEM!"

	# Give a random rare gem from Global.rare_gems
	var rare_gem = get_random_rare_gem()
	if rare_gem:
		reward_icon.texture = rare_gem
		reward_icon.visible = true
		reward_icon.expand = true
		reward_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		Global.rare_gems.append(rare_gem)  # Add to rare gems inventory
	else:
		print("Failed to load rare gem!")
		reward_icon.texture = null
		reward_icon.visible = false

func _on_claim_reward_pressed():
	# Close reward panel when claimed
	if is_exiting or reward_panel == null:
		return
	reward_panel.hide()

func get_random_rare_gem() -> Texture:
	# Get a random rare gem from a pre-defined folder, excluding ones already collected
	var dir = DirAccess.open("res://raregems")
	if dir == null:
		print("Error: Cannot open raregems directory")
		return null

	var available_paths := []
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".png"):
			var full_path = "res://raregems/" + file_name
			var already_has := false
			for gem_texture in Global.rare_gems:
				if gem_texture.resource_path == full_path:
					already_has = true
					break
			if not already_has:
				available_paths.append(full_path)
		file_name = dir.get_next()
	dir.list_dir_end()

	if available_paths.size() == 0:
		print("No new rare gem textures available in raregems/")
		return null

	var random_path = available_paths[randi() % available_paths.size()]
	return load(random_path) as Texture


func _on_play_again_pressed() -> void:
	# Restart the game
	is_exiting = true
	skip_animation = true

	while animation_running:
		await get_tree().process_frame

	Global.collected_gems = []
	current_session_score = 0
	get_tree().change_scene_to_file("res://scenes/level.tscn")

func _on_main_menu_pressed() -> void:
	# Return to main menu
	is_exiting = true
	skip_animation = true

	while animation_running:
		await get_tree().process_frame

	Global.collected_gems = []
	current_session_score = 0
	get_tree().change_scene_to_file("res://scenes/main.tscn")
