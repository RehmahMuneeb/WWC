extends Control

# Jewel data structure
var jewel_data = {
	"CrabJewel": {
		"progress": 30,
		"max": 100,
		"unlocked": false
	}
}



# Node references
@onready var jewel_node = $ScrollContainer/GridContainer/CrabJewel
@onready var jewel_image = jewel_node.get_node("JewelImage")
@onready var progress_label = jewel_node.get_node("Label")
@onready var add_button = jewel_node.get_node("Button")
@onready var coin_label = $CoinLabel
func _ready():
	update_jewel("CrabJewel")
	update_coin_display()
# Called whenever we need to refresh the UI
func update_jewel(jewel_id: String):
	var data = jewel_data[jewel_id]
	var percent = float(data.progress) / float(data.max)

	# Update the shader progress (revealing jewel)
	jewel_image.material.set_shader_parameter("progress", percent)

	# Update text label
	progress_label.text = "%d / %d" % [data.progress, data.max]

	# Disable Add button if already unlocked
	add_button.disabled = data.unlocked
	
func update_coin_display():
	if coin_label:
		coin_label.text = "COINS: " + str(Global.score)
# Called when Add Coins button is pressed
func _on_button_pressed():
	var id = "CrabJewel"
	var data = jewel_data[id]

	if Global.score >= 10 and not data.unlocked:
		Global.score -= 10  # Deduct from real coin pool
		data.progress += 10

		if data.progress >= data.max:
			data.progress = data.max
			data.unlocked = true

		update_jewel(id)
		update_coin_display()  # Update visible coin count
