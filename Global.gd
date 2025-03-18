extends Node

var score: int = 0
var bucket_capacity: int = 5  
var well_depth: int = 10  

const SAVE_PATH = "user://save_data.json"

func _ready():
	load_game()  # Load saved progress when game starts

func save_game():
	var save_data = {
		"score": score,
		"bucket_capacity": bucket_capacity,
		"well_depth": well_depth
	}
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(save_data))
	file.close()

func load_game():
	if FileAccess.file_exists(SAVE_PATH):
		var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		var content = file.get_as_text()
		file.close()

		var save_data = JSON.parse_string(content)
		if save_data:
			score = save_data.get("score", 0)
			bucket_capacity = save_data.get("bucket_capacity", 5)
			well_depth = save_data.get("well_depth", 10)

func reset_game():
	score = 0
	bucket_capacity = 5
	well_depth = 10
	save_game()  # Save reset data
