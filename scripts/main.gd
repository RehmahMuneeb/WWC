extends Control
@onready var reset_button = $ResetButton  # Add your actual reset button path
@onready var background = $Background  # Replace with your actual node path
var game_started = false  # To prevent multiple triggers
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
	# Enable input on the background
	background.mouse_filter = Control.MOUSE_FILTER_STOP

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
	
@onready var info_panel = $infopanel  # Replace with your actual panel path




func _input(event):
	if game_started:
		return

	if event is InputEventMouseButton and event.pressed:
		if not is_click_inside_excluded_controls(event.position):
			start_game()
	elif event is InputEventScreenTouch and event.pressed:
		if not is_click_inside_excluded_controls(event.position):
			start_game()

# Check if the click/touch is inside the panel or its children
func is_click_inside_excluded_controls(pos: Vector2) -> bool:
	var excluded_controls = [info_panel, reset_button]
	for control in excluded_controls:
		if is_click_inside_control(control, pos):
			return true
	return false

# Recursive function to check panel and its children
func is_click_inside_control(control: Control, pos: Vector2) -> bool:
	if control.get_global_rect().has_point(pos):
		return true
	for child in control.get_children():
		if child is Control:
			if is_click_inside_control(child, pos):
				return true
	return false

func start_game():
	game_started = true
	get_tree().change_scene_to_file("res://scenes/level.tscn")
