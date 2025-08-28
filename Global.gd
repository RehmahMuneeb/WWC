extends Node
var button_press_count = 0
var key_score: int = 0
var jewel_progress_data: Dictionary = {}  # Stores progress for each jewel
var jewel_unlock_data: Dictionary = {}    # Stores unlock status for each jewel
# In your Global.gd or similar save file
var current_chest_level := 1
var current_chest_progress := 0
var chest_targets := {}
var jewel_textures: Array[Texture2D] = []
var jewel_values: Array[int] = []# Item unlock thresholds
var unlock_thresholds = {
	"Item1": 1,
	"Item2": 2,
	"Item3": 3,
	"Item4": 4,
	"Item5": 5,
	"Item6": 6,
	"Item7": 7,
	"Item8": 8,
	"Item9": 9
}

# Track progress and unlocks
var bar_fill_count = 0
var unlocked_items = []
var highscore: int = 0

# Overlay and gem placement tracking
var overlay_visibility = {}  # Format: {"item_name/overlay_path": visible}
var placed_gems = {}         # Format: {"item_name": {"overlay_path": "gem_texture_path"}}
var gem_slot_map: Dictionary = {}

# Game progress system
var score: int = 0
var pending_score := 0
var bucket_capacity: int = 5000
var bucket_upgrade_cost: int = 150
var rare_gems: Array = []  # Stores paths to rare gem textures
var well_depth_limit: int = 500
var well_upgrade_cost: int = 300
var collected_gems: Array = []  # Stores paths to collected gem textures
var rare_gem_textures: Array[Texture2D] = [
	preload("res://raregems/owlredgem.png"),
	preload("res://raregems/owlgem.png"),
	preload("res://raregems/owlgem2.png"),
	preload("res://raregems/crabgem.png"),
	preload("res://raregems/crocodilegem.png"),
	preload("res://raregems/cupgem.png"),
	preload("res://raregems/dragon gem.png"),  # renamed to remove space
	preload("res://raregems/mermaidgem.png"),
	preload("res://raregems/skullgem.png"),
	preload("res://raregems/skullgem2.png"),
	preload("res://raregems/snakegem.png"),
	preload("res://raregems/tigergem.png")
]

func _ready():
	initialize_chest_targets()
	load_game()
	load_gem_slot_map()

func initialize_chest_targets():
	if chest_targets.is_empty():
		for level in range(1, 31):  # For 30 chest levels
			chest_targets[level] = 1000 * level

# Overlay visibility management
func save_overlay_visibility(item_name: String, overlay_path: String, visible: bool):
	var key = "%s/%s" % [item_name, overlay_path]
	overlay_visibility[key] = visible
	save_game()

func load_overlay_visibility(item_name: String, overlay_path: String) -> bool:
	var key = "%s/%s" % [item_name, overlay_path]
	# If there's a gem placed here, overlay should be hidden
	if placed_gems.get(item_name, {}).has(overlay_path):
		return false
	return overlay_visibility.get(key, true)  # Default to visible if not found

# Gem placement management
func save_placed_gem(item_name: String, overlay_path: String, gem_texture_path: String):
	if not placed_gems.has(item_name):
		placed_gems[item_name] = {}
	placed_gems[item_name][overlay_path] = gem_texture_path
	# Automatically hide the overlay when placing a gem
	save_overlay_visibility(item_name, overlay_path, false)
	save_game()

func remove_placed_gem(item_name: String, overlay_path: String):
	if placed_gems.has(item_name) and placed_gems[item_name].has(overlay_path):
		placed_gems[item_name].erase(overlay_path)
		if placed_gems[item_name].is_empty():
			placed_gems.erase(item_name)
		save_game()

func load_placed_gems() -> Dictionary:
	return placed_gems.duplicate(true)

func get_placed_gem(item_name: String, overlay_path: String) -> String:
	return placed_gems.get(item_name, {}).get(overlay_path, "")

# Game progression
func unlock_next_item():
	bar_fill_count += 1
	save_game()
	
	for item_name in unlock_thresholds:
		if unlock_thresholds[item_name] <= bar_fill_count and not item_name in unlocked_items:
			unlocked_items.append(item_name)
			save_game()
			return item_name
	return null

# Gem slot mapping
func load_gem_slot_map():
	var file := FileAccess.open("res://gem_slot_map.json", FileAccess.READ)
	if file:
		var json_text := file.get_as_text()
		var json := JSON.new()
		var result := json.parse(json_text)

		if result == OK:
			gem_slot_map = json.data

		else:
			push_error("Failed to parse JSON")
	else:
		push_error("Could not open JSON file")

# Gem collection
func collect_gem(texture: Texture2D) -> void:
	if texture and texture.resource_path:
		collected_gems.append(texture.resource_path)
		save_game()

func add_rare_gem(texture: Texture2D) -> void:
	if texture and texture.resource_path and not rare_gems.has(texture.resource_path):
		rare_gems.append(texture.resource_path)
		save_game()

# Save/load system
func save_game():
	
	var save_data = {
		"button_press_count": button_press_count,
		"highscore": Global.highscore,
		"jewel_progress": jewel_progress_data,
		"jewel_unlocks": jewel_unlock_data,
		"version": 6,  # Updated version number for chest progression
		"bar_fill_count": bar_fill_count,
		"unlocked_items": unlocked_items,
		"overlay_visibility": overlay_visibility,
		"placed_gems": placed_gems,
		"score": score,
		"bucket_capacity": bucket_capacity,
		"bucket_upgrade_cost": bucket_upgrade_cost,
		"well_depth_limit": well_depth_limit,
		"well_upgrade_cost": well_upgrade_cost,
		"collected_gems": collected_gems,
		"rare_gems": rare_gems,
		"current_chest_level": current_chest_level,
		"current_chest_progress": current_chest_progress,
		"chest_targets": chest_targets
	}
	
	var dir = DirAccess.open("user://")
	if not dir.dir_exists("saves"):
		dir.make_dir("saves")
	
	var save_path = "user://saves/game_save.dat"
	var file = FileAccess.open_encrypted_with_pass(save_path, FileAccess.WRITE, "your_encryption_key")
	
	if file:
		file.store_var(save_data)
		file.close()




func load_game():
	var save_path = "user://saves/game_save.dat"
	
	if FileAccess.file_exists(save_path):
		var file = FileAccess.open_encrypted_with_pass(save_path, FileAccess.READ, "your_encryption_key")
		
		if file:
			var save_data = file.get_var()
			file.close()
			
			if save_data.has("version"):
				match save_data.version:
					6: 
						button_press_count = save_data.get("button_press_count", 0)
						Global.highscore = save_data.get("highscore", 0)
						jewel_progress_data = save_data.get("jewel_progress", {})
						jewel_unlock_data = save_data.get("jewel_unlocks", {})
						 # Current version with chest progression
						bar_fill_count = save_data.get("bar_fill_count", 0)
						unlocked_items = save_data.get("unlocked_items", [])
						overlay_visibility = save_data.get("overlay_visibility", {})
						placed_gems = save_data.get("placed_gems", {})
						score = save_data.get("score", 0)
						bucket_capacity = save_data.get("bucket_capacity", 5000)
						bucket_upgrade_cost = save_data.get("bucket_upgrade_cost", 150)
						well_depth_limit = save_data.get("well_depth_limit", 500)
						well_upgrade_cost = save_data.get("well_upgrade_cost", 300)
						collected_gems = save_data.get("collected_gems", [])
						rare_gems = save_data.get("rare_gems", [])
						current_chest_level = save_data.get("current_chest_level", 1)
						current_chest_progress = save_data.get("current_chest_progress", 0)
						chest_targets = save_data.get("chest_targets", {})
						if chest_targets.is_empty():
							initialize_chest_targets()
					5:
						bar_fill_count = save_data.get("bar_fill_count", 0)
						unlocked_items = save_data.get("unlocked_items", [])
						overlay_visibility = save_data.get("overlay_visibility", {})
						placed_gems = save_data.get("placed_gems", {})
						score = save_data.get("score", 0)
						bucket_capacity = save_data.get("bucket_capacity", 5000)
						bucket_upgrade_cost = save_data.get("bucket_upgrade_cost", 150)
						well_depth_limit = save_data.get("well_depth_limit", 500)
						well_upgrade_cost = save_data.get("well_upgrade_cost", 300)
						collected_gems = save_data.get("collected_gems", [])
						rare_gems = save_data.get("rare_gems", [])
						current_chest_level = 1
						current_chest_progress = 0
						initialize_chest_targets()
					_:
						# Handle older versions
						bar_fill_count = save_data.get("bar_fill_count", 0)
						unlocked_items = save_data.get("unlocked_items", [])
						overlay_visibility = save_data.get("overlay_visibility", {})
						placed_gems = save_data.get("placed_gems", {})
						score = save_data.get("score", 0)
						bucket_capacity = save_data.get("bucket_capacity", 5000)
						bucket_upgrade_cost = save_data.get("bucket_upgrade_cost", 150)
						well_depth_limit = save_data.get("well_depth_limit", 500)
						well_upgrade_cost = save_data.get("well_upgrade_cost", 300)
						collected_gems = save_data.get("collected_gems", [])
						rare_gems = save_data.get("rare_gems", [])
						current_chest_level = 1
						current_chest_progress = 0
						initialize_chest_targets()
			else:
				# No version found - very old save
				bar_fill_count = save_data.get("bar_fill_count", 0)
				unlocked_items = save_data.get("unlocked_items", [])
				overlay_visibility = save_data.get("overlay_visibility", {})
				placed_gems = save_data.get("placed_gems", {})
				score = save_data.get("score", 0)
				bucket_capacity = save_data.get("bucket_capacity", 5000)
				bucket_upgrade_cost = save_data.get("bucket_upgrade_cost", 150)
				well_depth_limit = save_data.get("well_depth_limit", 500)
				well_upgrade_cost = save_data.get("well_upgrade_cost", 300)
				collected_gems = save_data.get("collected_gems", [])
				rare_gems = save_data.get("rare_gems", [])
				current_chest_level = 1
				current_chest_progress = 0
				initialize_chest_targets()
	else:

		initialize_chest_targets()

func reset_game():
	highscore = 0
	bar_fill_count = 0
	unlocked_items = []
	overlay_visibility = {}
	placed_gems = {}
	score = 0
	pending_score = 0
	bucket_capacity = 5000
	bucket_upgrade_cost = 150
	rare_gems = []
	well_depth_limit = 500
	well_upgrade_cost = 300
	collected_gems = []
	current_chest_level = 1
	current_chest_progress = 0
	initialize_chest_targets()
	save_game()


# Utility functions
func get_collected_gems_textures() -> Array:
	var textures = []
	for path in collected_gems:
		var texture = load(path)
		if texture:
			textures.append(texture)
	return textures

func get_rare_gems_textures() -> Array:
	var textures = []
	for path in rare_gems:
		var texture = load(path)
		if texture:
			textures.append(texture)
	return textures

func add_score(amount: int) -> void:
	pending_score += amount
	if pending_score >= bucket_capacity:
		pending_score = bucket_capacity

func claim_score() -> void:
	score += pending_score
	current_chest_progress += pending_score  # Also add to chest progress
	pending_score = 0
	save_game()

func upgrade_bucket() -> bool:
	if score >= bucket_upgrade_cost:
		score -= bucket_upgrade_cost
		bucket_capacity += 1000
		bucket_upgrade_cost += 100
		save_game()
		return true
	return false

func upgrade_well() -> bool:
	if score >= well_upgrade_cost:
		score -= well_upgrade_cost
		well_depth_limit += 100
		well_upgrade_cost += 200
		save_game()
		return true
	return false

# Chest progression helpers
func get_current_chest_target() -> int:
	return chest_targets.get(current_chest_level, 1000 * current_chest_level)

func check_chest_unlock() -> bool:
	if current_chest_progress >= get_current_chest_target():
		# Move to next chest
		current_chest_level = min(current_chest_level + 1, 30)
		current_chest_progress = 0
		save_game()
		return true
	return false
