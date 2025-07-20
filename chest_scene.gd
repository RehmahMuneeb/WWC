extends Control

var jewel_data = {
	"CrabJewel": {
		"progress": 0,
		"max": 800,
		"unlocked": false,
		"node_path": "ScrollContainer/GridContainer/CrabJewel",
		"shader_material": null,
		"min_fill": 0.22,  # Starts at 20%
		"max_fill": 0.72   # Ends at 80%
	},
	"CrocodileJewel": {
		"progress": 0,
		"max": 800,
		"unlocked": false,
		"node_path": "ScrollContainer/GridContainer/CrocodileJewel",
		"shader_material": null,
		"min_fill": 0.17,  # Default (0% to 100%)
		"max_fill": 0.74
	},
	"CupGem": {
		"progress": 0,
		"max": 800,
		"unlocked": false,
		"node_path": "ScrollContainer/GridContainer/CupGem",
		"shader_material": null,
		"min_fill": 0.24,  # Default (0% to 100%)
		"max_fill": 0.74
	},
	"DragonGem": {
		"progress": 0,
		"max": 800,
		"unlocked": false,
		"node_path": "ScrollContainer/GridContainer/DragonGem",
		"shader_material": null,
		"min_fill": 0.18,  # Default (0% to 100%)
		"max_fill": 0.70
	},
	"MermaidGem": {
		"progress": 0,
		"max": 900,
		"unlocked": false,
		"node_path": "ScrollContainer/GridContainer/MermaidGem",
		"shader_material": null,
		"min_fill": 0.17,  # Default (0% to 100%)
		"max_fill": 0.80
	},
	"OwlGem2": {
		"progress": 0,
		"max": 600,
		"unlocked": false,
		"node_path": "ScrollContainer/GridContainer/OwlGem2",
		"shader_material": null,
		"min_fill": 0.24,  # Default (0% to 100%)
		"max_fill": 0.68
	},
	"OwlGem": {
		"progress": 0,
		"max": 600,
		"unlocked": false,
		"node_path": "ScrollContainer/GridContainer/OwlGem",
		"shader_material": null,
		"min_fill": 0.24,  # Default (0% to 100%)
		"max_fill": 0.69
	},
	"OwlRedGem": {
		"progress": 0,
		"max": 800,
		"unlocked": false,
		"node_path": "ScrollContainer/GridContainer/OwlRedGem",
		"shader_material": null,
		"min_fill": 0.16,  # Default (0% to 100%)
		"max_fill": 0.77
	},
	"SkullGem2": {
		"progress": 0,
		"max": 500,
		"unlocked": false,
		"node_path": "ScrollContainer/GridContainer/SkullGem2",
		"shader_material": null,
		"min_fill": 0.23,  # Default (0% to 100%)
		"max_fill": 0.72
	},
	"SkullGem": {
		"progress": 0,
		"max": 500,
		"unlocked": false,
		"node_path": "ScrollContainer/GridContainer/SkullGem",
		"shader_material": null,
		"min_fill": 0.23,  # Default (0% to 100%)
		"max_fill": 0.72
	},
	"SnakeGem": {
		"progress": 0,
		"max": 800,
		"unlocked": false,
		"node_path": "ScrollContainer/GridContainer/SnakeGem",
		"shader_material": null,
		"min_fill": 0.21,  # Default (0% to 100%)
		"max_fill": 0.76
	},
	"TigerGem": {
		"progress": 0,
		"max": 800,
		"unlocked": false,
		"node_path": "ScrollContainer/GridContainer/TigerGem",
		"shader_material": null,
		"min_fill": 0.25,  # Default (0% to 100%)
		"max_fill": 0.79
	}
}

@onready var coin_label = $CoinLabel

func _ready():
	load_jewel_progress()  # Load saved progress first
	for jewel_id in jewel_data:
		initialize_jewel(jewel_id)
	update_coin_display()

func load_jewel_progress():
	# Load progress and unlock status from Global
	for jewel_id in jewel_data:
		if Global.jewel_progress_data.has(jewel_id):
			jewel_data[jewel_id]["progress"] = Global.jewel_progress_data[jewel_id]
		if Global.jewel_unlock_data.has(jewel_id):
			jewel_data[jewel_id]["unlocked"] = Global.jewel_unlock_data[jewel_id]

func save_jewel_progress(jewel_id: String):
	# Save progress and unlock status to Global
	Global.jewel_progress_data[jewel_id] = jewel_data[jewel_id]["progress"]
	Global.jewel_unlock_data[jewel_id] = jewel_data[jewel_id]["unlocked"]
	Global.save_game()

func initialize_jewel(jewel_id: String):
	var data = jewel_data[jewel_id]
	var jewel_node = get_node(data.node_path)
	var jewel_image = jewel_node.get_node("JewelImage")
	
	if jewel_image.material:
		data.shader_material = jewel_image.material.duplicate()
		jewel_image.material = data.shader_material
		# Set initial progress based on loaded data
		var fill_range = data.max_fill - data.min_fill
		var shader_progress = data.min_fill + (float(data.progress) / float(data.max)) * fill_range
		data.shader_material.set_shader_parameter("progress", shader_progress)
	else:
		push_error("No material assigned to JewelImage for " + jewel_id)
	
	var button = jewel_node.get_node("Button")
	button.pressed.connect(_on_jewel_button_pressed.bind(jewel_id))
	update_jewel(jewel_id)

func update_jewel(jewel_id: String):
	var data = jewel_data[jewel_id]
	var jewel_node = get_node(data.node_path)
	var progress_label = jewel_node.get_node("Label")
	var add_button = jewel_node.get_node("Button")
	
	# Calculate shader progress
	var fill_range = data.max_fill - data.min_fill
	var shader_progress = data.min_fill + (float(data.progress) / float(data.max)) * fill_range
	
	if data.shader_material:
		data.shader_material.set_shader_parameter("progress", shader_progress)
	
	progress_label.text = "%d / %d" % [data.progress, data.max]
	add_button.disabled = data.unlocked
	add_button.visible = not data.unlocked

func update_coin_display():
	coin_label.text = "COINS: " + str(Global.score)

func _on_jewel_button_pressed(jewel_id: String):
	var data = jewel_data[jewel_id]
	
	if Global.score >= 10 and not data.unlocked:
		Global.score -= 10
		data.progress += 10
		
		if data.progress >= data.max:
			data.progress = data.max
			data.unlocked = true
			_on_jewel_unlocked(jewel_id)
		
		update_jewel(jewel_id)
		update_coin_display()
		save_jewel_progress(jewel_id)  # Save after each change

func _on_jewel_unlocked(jewel_id: String):
	print(jewel_id + " unlocked!")
	save_jewel_progress(jewel_id)  # Save unlock status
	
	var gem_texture: Texture2D = null
	
	match jewel_id:
		"CrabJewel":
			gem_texture = preload("res://raregems/crabgem.png")
		"CrocodileJewel":
			gem_texture = preload("res://raregems/crocodilegem.png")
		"CupGem":
			gem_texture = preload("res://raregems/cupgem.png")
		"DragonGem":
			gem_texture = preload("res://raregems/dragon gem.png")
		"MermaidGem":
			gem_texture = preload("res://raregems/mermaidgem.png")
		"OwlGem2":
			gem_texture = preload("res://raregems/owlgem2.png")
		"OwlGem":
			gem_texture = preload("res://raregems/owlgem.png")
		"OwlRedGem":
			gem_texture = preload("res://raregems/owlredgem.png")
		"SkullGem2":
			gem_texture = preload("res://raregems/skullgem2.png")
		"SkullGem":
			gem_texture = preload("res://raregems/skullgem.png")
		"SnakeGem":
			gem_texture = preload("res://raregems/snakegem.png")
		"TigerGem":
			gem_texture = preload("res://raregems/tigergem.png")
	
	if gem_texture:
		if not Global.rare_gems.has(gem_texture.resource_path):
			Global.rare_gems.append(gem_texture.resource_path)
			Global.save_game()
			print("Added to inventory: ", gem_texture.resource_path)
	else:
		push_error("No matching gem texture found for: " + jewel_id)

func _on_texture_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")
