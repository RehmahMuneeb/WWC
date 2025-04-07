extends Node

# Global variables
var score: int = 0
var bucket_capacity: int = 5
var bucket_upgrade_cost: int = 150  # Starts at 150 instead of 50

# Well Depth Variables
var well_depth_limit: int = 500  # Default max depth
var well_upgrade_cost: int = 300  # Starts at 300 instead of 100

# Collected Gems
var collected_gems: Array[Texture2D] = []

# Save/Load Functions
func save_game():
	var save_data = {
		"score": score,
		"bucket_capacity": bucket_capacity,
		"bucket_upgrade_cost": bucket_upgrade_cost,
		"well_depth_limit": well_depth_limit,
		"well_upgrade_cost": well_upgrade_cost,
		"collected_gems": collected_gems # Save collected gems as well
	}
	var file = FileAccess.open("user://savegame.dat", FileAccess.WRITE)
	file.store_var(save_data)
	file.close()

func load_game():
	if FileAccess.file_exists("user://savegame.dat"):
		var file = FileAccess.open("user://savegame.dat", FileAccess.READ)
		var save_data = file.get_var()
		file.close()

		# Load game data
		score = save_data.get("score", 0)
		bucket_capacity = save_data.get("bucket_capacity", 5)
		bucket_upgrade_cost = save_data.get("bucket_upgrade_cost", 150)
		well_depth_limit = save_data.get("well_depth_limit", 500)
		well_upgrade_cost = save_data.get("well_upgrade_cost", 300)
		
		# Load collected gems from saved data
		collected_gems = save_data.get("collected_gems", [])

# Gem Collection Function
func collect_gem(texture: Texture2D) -> void:
	collected_gems.append(texture)
