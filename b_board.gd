extends Control

@onready var texture_button: TextureButton = $TextureButton
@onready var normal: Control = $TextureButton/Normal
@onready var hover: Control = $TextureButton/Hover

func _ready() -> void:
	hover.visible = false
	texture_button.mouse_entered.connect(_on_mouse_entered)
	texture_button.mouse_exited.connect(_on_mouse_exited)
	texture_button.pressed.connect(_on_pressed)

func _on_mouse_entered() -> void:
	SoundManager.play_sfx("UiWoodHover")
	hover.visible = true
	normal.visible = false

func _on_mouse_exited() -> void:
	hover.visible = false
	normal.visible = true

func _on_pressed() -> void:
	SoundManager.play_sfx("UiWoodClick")
	BattleEventBus.go("level_select")
