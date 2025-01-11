extends Node2D

var rock_scene: PackedScene = load("res://scenes/rock.tscn")

func _on_rock_timer_timeout():
	var rock = rock_scene.instantiate()
	
	$Rocks.add_child(rock)
	
# scoring 
var score = 0

func _process(delta):
	# Update the survival time
	score += 1
	var score_lable = $UI/Score
	score_lable.text = str(score) + "m"
