extends Control

signal pressed

@onready var confirm_button: TextureButton = %Confirm

func _ready() -> void:
	confirm_button.pressed.connect(_on_confirm_pressed)

func _on_confirm_pressed() -> void:
	emit_signal("pressed")
