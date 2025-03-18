extends Node

# Global variables
var score: int = 0
var bucket_capacity: int = 5
var bucket_upgrade_cost: int = 50

# Well Depth Variables
var well_depth_limit: int = 500  # Default max depth
var well_upgrade_cost: int = 100  # Initial upgrade cost

func save_game():
	var save_data = {
		"score": score,
		"bucket_capacity": bucket_capacity,
		"well_depth_limit": well_depth_limit
	}
	var file = FileAccess.open("user://savegame.dat", FileAccess.WRITE)
	file.store_var(save_data)
	file.close()

func load_game():
	if FileAccess.file_exists("user://savegame.dat"):
		var file = FileAccess.open("user://savegame.dat", FileAccess.READ)
		var save_data = file.get_var()
		file.close()

		score = save_data.get("score", 0)
		bucket_capacity = save_data.get("bucket_capacity", 5)
		well_depth_limit = save_data.get("well_depth_limit", 500)
