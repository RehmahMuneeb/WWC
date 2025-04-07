extends Control

var selected_gem = null

func _ready():
	# Connect gem selection signal
	$Tabs/GemsTab/Inventory.connect("gem_selected", Callable(self, "_on_gem_selected"))
	$SellButton.disabled = true

func _on_gem_selected(gem_node):
	selected_gem = gem_node
	$SellButton.disabled = false

func _on_SellButton_pressed():
	if selected_gem:
		var texture = selected_gem.get_node("TextureRect").texture
		Global.collected_gems.erase(texture)
		selected_gem.queue_free()
		selected_gem = null
		$SellButton.disabled = true


func _on_sell_button_pressed() -> void:
	pass # Replace with function body.
