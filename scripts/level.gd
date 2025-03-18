extends Node2D

var rock_scene: PackedScene = load("res://scenes/rock.tscn")

var score = 0  # Always start at 0m

func _on_rock_timer_timeout():
	var rock = rock_scene.instantiate()
	$Rocks.add_child(rock)

func _ready():
	score = 0  # Always start at 0

func _process(delta):
	score += 1
	var score_label = $UI/Score
	score_label.text = str(score) + "m"

	if score >= Global.well_depth_limit:  
		print("Reached max depth! Returning to home screen.")
		get_tree().change_scene_to_file("res://scenes/main.tscn")  # Go back to home screen
