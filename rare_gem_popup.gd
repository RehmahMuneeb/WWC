extends Control

@onready var texture_rect = $Panel/TextureRect
@onready var close_button = $Panel/Button

signal popup_closed

func show_gem(texture: Texture2D):
	texture_rect.texture = texture
	visible = true

func _ready():
	visible = false
	close_button.pressed.connect(_on_close_pressed)

func _on_close_pressed():
	visible = false
	emit_signal("popup_closed")
