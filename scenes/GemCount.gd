extends Button

func _process(_delta: float) -> void:
	text ="X " + str(Global.collected_gems.size())
