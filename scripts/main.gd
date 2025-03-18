extends Control

@onready var coin_label = $Coinslabel
@onready var capacity_button =$"infopanel/Bucket Capacity/Button" 

var bucket_capacity = 5  # Initial bucket capacity
var capacity_upgrade_cost = 50  # Initial cost

func _ready() -> void:
	update_ui()
	capacity_button.pressed.connect(upgrade_capacity)

func _process(_delta):
	update_ui()  # Refresh UI every frame to show updated coins

func update_ui():
	coin_label.text = "Coins: " + str(Global.score)  # Use global coins
	capacity_button.text = "Upgrade (" + str(capacity_upgrade_cost) + " Coins)"
	capacity_button.disabled = Global.score < capacity_upgrade_cost  # Disable if not enough coins

func upgrade_capacity():
	if Global.score >= capacity_upgrade_cost:
		Global.score -= capacity_upgrade_cost  # Deduct coins
		bucket_capacity += 1  # Increase bucket space
		capacity_upgrade_cost += 50  # Cost increases per upgrade
		update_ui()
	else:
		print("Not enough coins!")

func _on_play_pressed():
	get_tree().change_scene_to_file("res://scenes/level.tscn")
