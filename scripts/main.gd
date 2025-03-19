extends Control

@onready var coin_label = $Coins/Coinslabel
@onready var capacity_button = $"infopanel/Bucket Capacity/Button"
@onready var well_button = $infopanel/Button  # Well depth upgrade button

# New Labels for Bucket Capacity & Well Depth
@onready var bucket_capacity_label = $"infopanel/Bucket Capacity/CapacityLabel"
@onready var well_depth_label = $"infopanel/Well Depth/DepthLabel"

func _ready() -> void:
	update_ui()
	capacity_button.pressed.connect(upgrade_capacity)
	well_button.pressed.connect(upgrade_well_depth)

func _process(_delta):
	update_ui()  # Refresh UI

func update_ui():
	# Update Coins Display
	coin_label.text = "Coins: " + str(Global.score)  

	# Update Button Text
	capacity_button.text = str(Global.bucket_upgrade_cost) + "\nUpgrade"
	well_button.text = str(Global.well_upgrade_cost) + "\nUpgrade"

	# Update Labels for Bucket Capacity & Well Depth
	bucket_capacity_label.text ="CAPACITY: " + str(Global.bucket_capacity)  
	well_depth_label.text = "DEPTH: " + str(Global.well_depth_limit)

	# Disable Buttons if Not Enough Coins
	capacity_button.disabled = Global.score < Global.bucket_upgrade_cost
	well_button.disabled = Global.score < Global.well_upgrade_cost

func upgrade_capacity():
	if Global.score >= Global.bucket_upgrade_cost:
		Global.score -= Global.bucket_upgrade_cost  
		Global.bucket_capacity += 1  # Increase by 1  
		Global.bucket_upgrade_cost *= 2  # Multiply upgrade cost by 2  
		Global.save_game()
		update_ui()

func upgrade_well_depth():
	if Global.score >= Global.well_upgrade_cost:
		Global.score -= Global.well_upgrade_cost  
		Global.well_depth_limit += 500  # Increase depth limit by 500  
		Global.well_upgrade_cost *= 2  # Multiply upgrade cost by 2  
		Global.save_game()
		update_ui()

func _on_play_pressed():
	get_tree().change_scene_to_file("res://scenes/level.tscn")
