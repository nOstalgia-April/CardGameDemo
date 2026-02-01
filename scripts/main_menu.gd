extends Control
@export var BGM: AudioStream

@onready var start_battle_button: TextureButton = $StartBattleButton
@onready var start_battle_anim: AnimationPlayer = $StartBattleButton/AnimationPlayer
@onready var info_button: TextureButton = $InfoButton
@onready var about_info_layer: CanvasLayer = $AboutInfoLayer

func _on_start_pressed() -> void:
	BattleEventBus.go("level_select")
	SoundManager.play_sfx("MainPlayPress")

func _ready() -> void:
	SoundManager.play_bgm(BGM)
	if about_info_layer != null:
		about_info_layer.visible = false
	if start_battle_button != null:
		var start_texture := start_battle_button.texture_hover if start_battle_button.texture_hover != null else start_battle_button.texture_normal
		_apply_click_mask(start_battle_button, start_texture)
		start_battle_button.mouse_entered.connect(_on_start_hovered)
		start_battle_button.mouse_exited.connect(_on_start_unhovered)
	if info_button != null:
		_apply_click_mask(info_button, info_button.texture_normal)
		info_button.pressed.connect(_on_info_pressed)

func _on_start_hovered() -> void:
	if start_battle_anim != null:
		start_battle_anim.play("hover")
	SoundManager.play_sfx("MainPlaySplat")

func _on_start_unhovered() -> void:
	if start_battle_anim != null:
		start_battle_anim.play("RESET")

func _on_info_pressed() -> void:
	if about_info_layer != null:
		about_info_layer.visible = !about_info_layer.visible
	SoundManager.play_sfx("ComputerClick")

func _apply_click_mask(button: TextureButton, texture: Texture2D) -> void:
	if button == null or texture == null:
		return
	var image := texture.get_image()
	if image == null:
		return
	if image.is_compressed():
		image.decompress()
	var bitmap := BitMap.new()
	bitmap.create_from_image_alpha(image, 0.1)
	button.texture_click_mask = bitmap
