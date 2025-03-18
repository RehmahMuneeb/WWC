extends Control

@onready var coin_label = $Coins/Coinslabel
@onready var capacity_button = $"infopanel/Bucket Capacity/Button"
@onready var well_button = $infopanel/Button # New button

func _ready() -> void:
	update_ui()
	capacity_button.pressed.connect(upgrade_capacity)
	well_button.pressed.connect(upgrade_well_depth)  # Connect button

func _process(_delta):
	update_ui()  # Refresh UI

func update_ui():
	coin_label.text = "Coins: " + str(Global.score)  
	capacity_button.text = "Upgrade (" + str(Global.bucket_upgrade_cost) + " Coins)"
	well_button.text = "Upgrade (" + str(Global.well_upgrade_cost) + " Coins)"

	capacity_button.disabled = Global.score < Global.bucket_upgrade_cost
	well_button.disabled = Global.score < Global.well_upgrade_cost

func upgrade_capacity():
	if Global.score >= Global.bucket_upgrade_cost:
		Global.score -= Global.bucket_upgrade_cost  
		Global.bucket_capacity += 1  
		Global.bucket_upgrade_cost += 50  
		Global.save_game()
		update_ui()

func upgrade_well_depth():
	if Global.score >= Global.well_upgrade_cost:
		Global.score -= Global.well_upgrade_cost  
		Global.well_depth_limit += 500  # Increase depth limit
		Global.well_upgrade_cost += 100  
		Global.save_game()
		update_ui()

func _on_play_pressed():
	get_tree().change_scene_to_file("res://scenes/level.tscn")
