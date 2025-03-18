extends Control

@onready var coin_label = $Coins/Coinslabel
@onready var capacity_button = $"infopanel/Bucket Capacity/Button"
@onready var depth_button = $infopanel/Button

var capacity_upgrade_cost = 50  
var depth_upgrade_cost = 100  

func _ready() -> void:
	update_ui()
	capacity_button.pressed.connect(upgrade_capacity)
	depth_button.pressed.connect(upgrade_depth)

func _process(_delta):
	update_ui()  

func update_ui():
	coin_label.text = "Coins: " + str(Global.score)  
	capacity_button.text = "Upgrade Bucket (" + str(capacity_upgrade_cost) + " Coins)"
	depth_button.text = "Upgrade Well (" + str(depth_upgrade_cost) + " Coins)"

	capacity_button.disabled = Global.score < capacity_upgrade_cost
	depth_button.disabled = Global.score < depth_upgrade_cost

func upgrade_capacity():
	if Global.score >= capacity_upgrade_cost:
		Global.score -= capacity_upgrade_cost  
		Global.bucket_capacity += 1  
		capacity_upgrade_cost += 50  
		Global.save_game()  # Save after upgrading
		update_ui()
	else:
		print("Not enough coins!")

func upgrade_depth():
	if Global.score >= depth_upgrade_cost:
		Global.score -= depth_upgrade_cost  
		Global.well_depth += 5  
		depth_upgrade_cost += 100  
		Global.save_game()  # Save after upgrading
		update_ui()
	else:
		print("Not enough coins!")

func _on_play_pressed():
	get_tree().change_scene_to_file("res://scenes/level.tscn")
