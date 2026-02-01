extends Control

@export var hover_offset: Vector2 = Vector2(120, 0)
@export var hover_duration: float = 0.3
@export var back_scene_key: String = "main"
@export var battle_scene_key: String = "battle"

const BACK_TEXTURE: Texture2D = preload("res://assets/UI/Folder/ui_back_1.png")
const REMAKE_TEXTURE: Texture2D = preload("res://assets/UI/Folder/ui_remake.png")

@onready var fancy_back_button: TextureButton = %FancyBackButton
@onready var cover_image: TextureRect = %CoverImage

var _cover_origin: Vector2 = Vector2.ZERO
var _is_level_select: bool = false

func _ready() -> void:
	_is_level_select = _detect_level_select()
	fancy_back_button.texture_normal = BACK_TEXTURE if _is_level_select else REMAKE_TEXTURE
	_apply_click_mask()
	if cover_image != null:
		_cover_origin = cover_image.position
	if fancy_back_button != null:
		fancy_back_button.mouse_entered.connect(_on_mouse_entered)
		fancy_back_button.mouse_exited.connect(_on_mouse_exited)
		fancy_back_button.pressed.connect(_on_pressed)

func _on_mouse_entered() -> void:
	SoundManager.play_sfx("UiBack")
	_tween_cover_to(_cover_origin + hover_offset)

func _on_mouse_exited() -> void:
	_tween_cover_to(_cover_origin)

func _on_pressed() -> void:
	if _is_level_select:
		BattleEventBus.go(back_scene_key)
	else:
		var scene: Node = get_tree().current_scene
		if scene.has_method("restart_level"):
			scene.restart_level()
		else:
			BattleEventBus.go(battle_scene_key)
	SoundManager.play_sfx('ComputerClick')

func _tween_cover_to(target: Vector2) -> void:
	if cover_image == null:
		return
	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(cover_image, "position", target, hover_duration)

func _apply_click_mask() -> void:
	if fancy_back_button == null:
		return
	var tex: Texture2D = fancy_back_button.texture_normal
	if tex == null:
		return
	var img: Image = tex.get_image()
	if img == null:
		return
	var mask := BitMap.new()
	mask.create_from_image_alpha(img, 0.1)
	fancy_back_button.texture_click_mask = mask

func _detect_level_select() -> bool:
	var scene: Node = get_tree().current_scene
	var script: Script = scene.get_script()
	var path: String = str(script.resource_path)
	return path.ends_with("scripts/level_select.gd")
