extends Label

func _process(delta: float) -> void:
	# Update the label text to show the current score
	text = "Score: " + str(Global.score)
