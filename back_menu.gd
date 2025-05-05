extends Control

func _ready():
	$"Bucket Capacity2/ScoreLabel".text = "Score: %d" % Global.score



func _on_play_again_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/level.tscn")


func _on_main_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")
