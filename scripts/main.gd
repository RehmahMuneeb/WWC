extends Control

@onready var coin_label = $Coins/Coinslabel
@onready var capacity_button = $"infopanel/Bucket Capacity/Button"
@onready var well_button = $infopanel/Button  # Well depth upgrade button

# New Labels for Bucket Capacity & Well Depth
@onready var bucket_capacity_label = $"infopanel/Bucket Capacity/CapacityLabel"
@onready var well_depth_label = $"infopanel/Well Depth/DepthLabel"

func _ready() -> void:
	AdController.load_banner() 
	AdController.show_banner()  # Will auto-show
	update_ui()


func _process(_delta):
	update_ui()  # Refresh UI

func update_ui():
	# Update Coins Display
	coin_label.text = "COINS: " + str(Global.score)  





func _on_play_pressed():
	get_tree().change_scene_to_file("res://scenes/level.tscn")


func _on_rare_items_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/RareItems.tscn")


func _on_items_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/MainInventory.tscn")


func _on_inventory_pressed() -> void:
	get_tree().change_scene_to_file("res://crafting.tscn")


func _on_button_pressed() -> void:
	Global.reset_game()


func _on_cest_button_pressed() -> void:
	get_tree().change_scene_to_file("res://ChestScene.tscn")
