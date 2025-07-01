extends Control

# UI elements
@onready var bucket_icon: TextureRect = $"Bucket Capacity2/Bucket"
@onready var chest_icon: TextureRect = $"Bucket Capacity2/Chest"
@onready var chest_progress_bar: ProgressBar = $"Bucket Capacity2/ProgressBar"
@onready var progress_label: Label = chest_progress_bar.get_node("ProgressLabel")
@onready var gem_score_label: Label = $"Bucket Capacity2/GemScoreLabel"
@onready var multiply_label: Label = $"AD BAR2/Multiply"
@onready var reward_panel: Control = $RewardPanel
@onready var reward_label: Label = reward_panel.get_node("RewardLabel")
@onready var reward_button: Button = reward_panel.get_node("ClaimButton")
@onready var reward_icon: TextureRect = reward_panel.get_node("GemIcon")
@onready var gem_sound_player: AudioStreamPlayer2D = $GemSoundPlayer
@onready var watch_ad_button: Button = $"AD BAR2/watchadbutton"

var jewel_textures: Array[Texture2D] = []
var jewel_values: Array[int] = []
var base_gem_score_total := 0

# Constants and variables
const BASE_COINS_TO_UNLOCK := 1000
var chest_unlocked := false
var current_target := BASE_COINS_TO_UNLOCK
var animation_speed := 1.0
const FAST_SPEED := 0.2
var speed_increased := false
var current_session_score := 0
var skip_animation := false
var animation_running := false
var total_multiplied_score := 0
var is_exiting := false
var ad_requested_during_animation := false  # Track if ad was requested during animation

func _ready():
	jewel_textures = Global.jewel_textures
	jewel_values = Global.jewel_values

	current_session_score = 0
	is_exiting = false

	initialize_chest_progression()
	gem_score_label.text = "+0"
	multiply_label.text = "x3: 0"
	update_chest_ui()
	reward_panel.hide()
	reward_button.pressed.connect(_on_claim_reward_pressed)
	watch_ad_button.pressed.connect(_on_watchadbutton_pressed)
	AdController.load_rewarded()
	AdController.reward_earned.connect(_on_reward_earned)
	AdController.rewarded_failed.connect(_on_rewarded_failed)
	AdController.rewarded_closed.connect(_on_rewarded_closed)
	animate_gems_with_float_motion()

func initialize_chest_progression():
	if Global.chest_targets.is_empty():
		for level in range(1, 31):
			Global.chest_targets[level] = BASE_COINS_TO_UNLOCK * level
	Global.current_chest_level = clamp(Global.current_chest_level, 1, 30)
	current_target = Global.chest_targets[Global.current_chest_level]
	Global.score = Global.current_chest_progress

func update_chest_ui():
	chest_progress_bar.max_value = current_target
	chest_progress_bar.value = Global.score
	progress_label.text = "%d / %d" % [Global.score, current_target]

func update_chest_progress():
	var end_value = min(Global.score, current_target)
	Global.current_chest_progress = end_value
	var tween = create_tween()
	tween.tween_property(chest_progress_bar, "value", end_value, 0.5)
	tween.tween_callback(update_chest_ui)
	if not chest_unlocked and Global.score >= current_target:
		chest_unlocked = true
		unlock_chest()

func _input(event):
	if not speed_increased and ((event is InputEventScreenTouch and event.pressed) or 
	   (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT)):
		speed_increased = true
		animation_speed = FAST_SPEED

func animate_gems_with_float_motion() -> void:
	animation_running = true
	watch_ad_button.disabled = true  # Disable button at start of animation
	var score_per_gem := 1000
	var gem_textures = Global.get_collected_gems_textures()
	for gem_texture in gem_textures:
		if gem_texture == null:
			continue
		if skip_animation:
			current_session_score += score_per_gem
			Global.score += score_per_gem
			Global.current_chest_progress = Global.score
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
		if gem_sound_player:
			gem_sound_player.play()
		current_session_score += score_per_gem
		Global.score += score_per_gem
		Global.current_chest_progress = Global.score
		base_gem_score_total += score_per_gem
		total_multiplied_score += score_per_gem * 3
		gem_score_label.text = "+%d" % current_session_score
		multiply_label.text = "x3: %d" % total_multiplied_score
		update_chest_progress()
		if not skip_animation:
			show_score_popup("+%d" % score_per_gem, chest_icon.get_global_position())
			await get_tree().create_timer(0.2 * animation_speed).timeout
	if skip_animation:
		total_multiplied_score = current_session_score * 3
		multiply_label.text = "x3: %d" % total_multiplied_score
	
	animation_running = false
	watch_ad_button.disabled = false  # Re-enable button when animation finishes
	
	# If ad was requested during animation, show it now
	if ad_requested_during_animation:
		ad_requested_during_animation = false
		_on_watchadbutton_pressed()

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

func _on_watchadbutton_pressed() -> void:
	print("Watch Ad button pressed")
	if animation_running:
		# If animation is running, mark that we want to show ad after it finishes
		ad_requested_during_animation = true
		return
	
	watch_ad_button.disabled = true
	AdController.show_rewarded()

func _on_reward_earned(amount: int, ad_type: String):
	print("Reward earned: ", amount, ad_type)
	await play_reward_animation()
	AdController.load_rewarded()
	watch_ad_button.disabled = false

func _on_rewarded_failed(error: String):
	print("Rewarded ad failed: ", error)
	watch_ad_button.disabled = false

func _on_rewarded_closed():
	print("Rewarded ad closed")
	watch_ad_button.disabled = false
	AdController.load_rewarded()

func play_reward_animation() -> void:
	if animation_running:
		return
	print("Playing reward animation (3x bonus)")
	animation_running = true
	watch_ad_button.disabled = true  # Disable button during reward animation
	var gem_textures := Global.get_collected_gems_textures()
	var score_per_gem := 1000
	base_gem_score_total = 0
	total_multiplied_score = 0
	current_session_score = 0
	for i in 3:
		for gem_texture in gem_textures:
			if gem_texture == null:
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
				var t := elapsed / duration
				var linear = start_pos.lerp(end_pos, t)
				var offset = Vector2(0, sin(t * PI * frequency) * -amplitude)
				gem.global_position = linear + offset
				await get_tree().process_frame
				elapsed += get_process_delta_time()
			gem.queue_free()
			if gem_sound_player:
				gem_sound_player.play()
			show_score_popup("+%d" % score_per_gem, chest_icon.get_global_position())
			await get_tree().create_timer(0.2 * animation_speed).timeout
			base_gem_score_total += score_per_gem
	Global.score += base_gem_score_total
	Global.current_chest_progress = Global.score
	current_session_score = base_gem_score_total
	total_multiplied_score = base_gem_score_total
	gem_score_label.text = "+%d" % current_session_score
	multiply_label.text = "x3: %d" % total_multiplied_score
	update_chest_progress()
	Global.collected_gems = []
	Global.save_game()
	animation_running = false
	watch_ad_button.disabled = false  # Re-enable button after reward animation

func _on_claim_reward_pressed():
	if is_exiting or reward_panel == null:
		return
	reward_panel.hide()

func unlock_chest():
	print("Chest %d Unlocked!" % Global.current_chest_level)
	show_reward_panel()
	Global.score = 0
	Global.current_chest_progress = 0
	if Global.current_chest_level < 30:
		Global.current_chest_level += 1
		current_target = Global.chest_targets[Global.current_chest_level]
	else:
		print("All chests unlocked!")
	update_chest_ui()
	Global.save_game()
	chest_unlocked = false

func show_reward_panel():
	if is_exiting or reward_panel == null:
		return
	reward_panel.show()
	reward_label.text = "YOU RECEIVED A RARE GEM!"
	var rare_gem_texture = get_random_rare_gem()
	if rare_gem_texture:
		reward_icon.texture = rare_gem_texture
		reward_icon.visible = true
		reward_icon.expand = true
		reward_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		Global.add_rare_gem(rare_gem_texture)
	else:
		print("Failed to load rare gem!")
		reward_icon.texture = null
		reward_icon.visible = false

func get_random_rare_gem() -> Texture:
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
			if not Global.rare_gems.has(full_path):
				available_paths.append(full_path)
		file_name = dir.get_next()
	dir.list_dir_end()
	if available_paths.size() == 0:
		print("Player has all rare gems!")
		return null
	var random_path = available_paths[randi() % available_paths.size()]
	return load(random_path) as Texture

func _on_play_again_pressed() -> void:
	is_exiting = true
	skip_animation = true
	while animation_running:
		await get_tree().process_frame
	Global.collected_gems = []
	current_session_score = 0
	AdController.game_over_count = 0
	get_tree().change_scene_to_file("res://scenes/level.tscn")

func _on_main_menu_pressed() -> void:
	is_exiting = true
	skip_animation = true
	while animation_running:
		await get_tree().process_frame
	Global.collected_gems = []
	current_session_score = 0
	get_tree().change_scene_to_file("res://scenes/main.tscn")
