extends Node

@onready var player = $Player

func _ready():
	# Only one MusicManager should exist
	if get_node("/root").has_node("MusicManager") and get_node("/root/MusicManager") != self:
		queue_free()
	else:
		get_tree().root.add_child(self)
		self.owner = null  # So it persists across scenes
