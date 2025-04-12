extends Node2D

var rock_scene: PackedScene = load("res://scenes/rock.tscn")

var score = 0  # Always start at 0m

@onready var rock_timer = $Rocks/RockTimer # Make sure this node exists
@onready var score_label = $UI/Score

func _ready():
	score = 0
	rock_timer.wait_time = 2.0  # default delay
	rock_timer.start()

func _process(delta):
	score += 1
	score_label.text = str(score) + "m"

	update_rock_spawn_speed()

func update_rock_spawn_speed():
	var depth_in_cycle = score % 6000
	if depth_in_cycle >= 1000 and depth_in_cycle < 2000:
		if rock_timer.wait_time != 0.5:
			rock_timer.wait_time = 0.5  # faster during lava
			rock_timer.start()
	else:
		if rock_timer.wait_time != 3.0:
			rock_timer.wait_time = 3.0  # normal speed
			rock_timer.start()

func _on_rock_timer_timeout():
	var rock = rock_scene.instantiate()
	$Rocks.add_child(rock)
