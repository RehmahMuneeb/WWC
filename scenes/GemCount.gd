extends Label

func _process(_delta: float) -> void:
	text = "GEMS: " + str(Global.collected_gems.size())
