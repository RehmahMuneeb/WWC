extends Node

# Item unlock thresholds
var unlock_thresholds = {
	"Item0": 1,
	"Item1": 2,
	"Item2": 3,
	"Item3": 4,
	"Item4": 5,
	"Item5": 6,
	"Item6": 7,
	"Item7": 8,
	"Item8": 9,
	"Item9": 10
}

# Track progress and unlocks
var bar_fill_count = 0
var unlocked_items = []

# Gem and Game Progress System
var gem_slot_map: Dictionary = {}
var score: int = 0
var pending_score := 0
var bucket_capacity: int = 5000
var bucket_upgrade_cost: int = 150
var rare_gems: Array = []  # Stores paths to rare gem textures
var well_depth_limit: int = 500
var well_upgrade_cost: int = 300
var collected_gems: Array = []  # Stores paths to collected gem textures

func _ready():
	load_game()
	load_gem_slot_map()

func unlock_next_item():
	bar_fill_count += 1
	save_game()
	
	for item_name in unlock_thresholds:
		if unlock_thresholds[item_name] <= bar_fill_count and not item_name in unlocked_items:
			unlocked_items.append(item_name)
			save_game()
			return item_name
	return null

func load_gem_slot_map():
	var file := FileAccess.open("res://gem_slot_map.json", FileAccess.READ)
	if file:
		var json_text := file.get_as_text()
		var json := JSON.new()
		var result := json.parse(json_text)

		if result == OK:
			gem_slot_map = json.data
			print("Gem-slot map loaded:", gem_slot_map)
		else:
			push_error("Failed to parse JSON")
	else:
		push_error("Could not open JSON file")

func collect_gem(texture: Texture2D) -> void:
	if texture and texture.resource_path:
		collected_gems.append(texture.resource_path)
		save_game()

func add_rare_gem(texture: Texture2D) -> void:
	if texture and texture.resource_path and not rare_gems.has(texture.resource_path):
		rare_gems.append(texture.resource_path)
		save_game()

func save_game():
	var save_data = {
		"version": 3,
		"bar_fill_count": bar_fill_count,
		"unlocked_items": unlocked_items,
		"score": score,
		"bucket_capacity": bucket_capacity,
		"bucket_upgrade_cost": bucket_upgrade_cost,
		"well_depth_limit": well_depth_limit,
		"well_upgrade_cost": well_upgrade_cost,
		"collected_gems": collected_gems,
		"rare_gems": rare_gems
	}
	
	var dir = DirAccess.open("user://")
	if not dir.dir_exists("saves"):
		dir.make_dir("saves")
	
	var save_path = "user://saves/game_save.dat"
	var file = FileAccess.open_encrypted_with_pass(save_path, FileAccess.WRITE, "your_encryption_key")
	
	if file:
		file.store_var(save_data)
		file.close()
		print("Game saved successfully")
	else:
		printerr("Failed to save game: ", FileAccess.get_open_error())

func load_game():
	var save_path = "user://saves/game_save.dat"
	
	if FileAccess.file_exists(save_path):
		var file = FileAccess.open_encrypted_with_pass(save_path, FileAccess.READ, "your_encryption_key")
		
		if file:
			var save_data = file.get_var()
			file.close()
			
			if save_data.has("version"):
				match save_data.version:
					3:
						bar_fill_count = save_data.get("bar_fill_count", 0)
						unlocked_items = save_data.get("unlocked_items", [])
						score = save_data.get("score", 0)
						bucket_capacity = save_data.get("bucket_capacity", 5000)
						bucket_upgrade_cost = save_data.get("bucket_upgrade_cost", 150)
						well_depth_limit = save_data.get("well_depth_limit", 500)
						well_upgrade_cost = save_data.get("well_upgrade_cost", 300)
						collected_gems = save_data.get("collected_gems", [])
						rare_gems = save_data.get("rare_gems", [])
					2:
						bar_fill_count = save_data.get("bar_fill_count", 0)
						unlocked_items = save_data.get("unlocked_items", [])
						score = save_data.get("score", 0)
						bucket_capacity = save_data.get("bucket_capacity", 5000)
						bucket_upgrade_cost = save_data.get("bucket_upgrade_cost", 150)
						well_depth_limit = save_data.get("well_depth_limit", 500)
						well_upgrade_cost = save_data.get("well_upgrade_cost", 300)
						collected_gems = []
						rare_gems = []
					1:
						bar_fill_count = save_data.get("bar_fill_count", 0)
						unlocked_items = save_data.get("unlocked_items", [])
						score = 0
						bucket_capacity = 5000
						bucket_upgrade_cost = 150
						well_depth_limit = 500
						well_upgrade_cost = 300
						collected_gems = []
						rare_gems = []
			else:
				bar_fill_count = save_data.get("bar_fill_count", 0)
				unlocked_items = save_data.get("unlocked_items", [])
				score = 0
				bucket_capacity = 5000
				bucket_upgrade_cost = 150
				well_depth_limit = 500
				well_upgrade_cost = 300
				collected_gems = []
				rare_gems = []
	else:
		print("No save file found, starting new game")

func reset_game():
	bar_fill_count = 0
	unlocked_items = []
	score = 0
	pending_score = 0
	bucket_capacity = 5000
	bucket_upgrade_cost = 150
	rare_gems = []
	well_depth_limit = 500
	well_upgrade_cost = 300
	collected_gems = []
	save_game()
	print("Game progress reset")

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
