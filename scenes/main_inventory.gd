extends Control

@onready var gem_inventory = $Tabs/GEMS/Inventory
@onready var sell_button = $SellButton  # Your button
@onready var coin_label = $Coins/Coinslabel

var selected_texture: Texture = null

func _ready():
	gem_inventory.connect("gem_clicked", Callable(self, "_on_gem_clicked"))
	sell_button.pressed.connect(_on_sell_pressed)
	update_coin_label()

func _on_gem_clicked(texture: Texture):
	selected_texture = texture
	print("Selected texture to sell:", texture)

func _on_sell_pressed():
	if selected_texture and Global.collected_gems.has(selected_texture):
		Global.collected_gems.erase(selected_texture)
		Global.score += 10  # Sell value per gem
		gem_inventory.update_inventory()
		update_coin_label()
		selected_texture = null

func update_coin_label():
	if coin_label:
		coin_label.text = "COINS: " + str(Global.score)  # Access score as coins


func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn") 
