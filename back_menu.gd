extends Control

var bucket_icon: TextureRect
var chest_icon: TextureRect

func _ready():
	# Update score label
	$"Bucket Capacity2/ScoreLabel".text = "Score: %d" % Global.score

	bucket_icon = $"Bucket Capacity2/Bucket"
	chest_icon = $"AD BAR2/Chest"
	
	# Start animated gem transfer
	await animate_gems_with_float_motion()

func animate_gems_with_float_motion() -> void:
	for gem_texture in Global.collected_gems:
		if gem_texture == null:
			continue

		var gem = TextureRect.new()
		gem.texture = gem_texture
		gem.expand = true
		gem.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		gem.custom_minimum_size = Vector2(64, 64)
		gem.anchor_left = 0
		gem.anchor_top = 0
		gem.anchor_right = 0
		gem.anchor_bottom = 0

		add_child(gem)

		# Get start and end positions
		var start_pos = bucket_icon.get_global_position()
		var end_pos = chest_icon.get_global_position()
		gem.global_position = start_pos

		# Animate manually
		var duration := 1  # Slow and floaty
		var elapsed := 0.0
		var amplitude := 40  # How high the wave goes
		var frequency := 3.0  # How many waves
		while elapsed < duration:
			var t := elapsed / duration
			var linear = start_pos.lerp(end_pos, t)
			var offset = Vector2(0, sin(t * PI * frequency) * -amplitude)  # Float upward in a wave
			gem.global_position = linear + offset
			await get_tree().process_frame
			elapsed += get_process_delta_time()
		
		# Cleanup
		gem.queue_free()
		await get_tree().create_timer(0.2).timeout
