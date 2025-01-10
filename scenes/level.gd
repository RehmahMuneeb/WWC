extends Node2D

var rock_scene: PackedScene = load("res://scenes/rock.tscn")

func _on_rock_timer_timeout():
	var rock = rock_scene.instantiate()
	
	$Rocks.add_child(rock)
