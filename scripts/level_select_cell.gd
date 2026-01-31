extends Control
class_name LevelSelectCell

signal pressed(cell: LevelSelectCell)

@export var base_texture_even: Texture2D = preload("res://assets/Board/DefaultCell.png")
@export var base_texture_odd: Texture2D = preload("res://assets/Board/DefaultCell2.png")
@export var hover_texture: Texture2D = preload("res://assets/Board/WhiteHover.png")
@export var select_texture: Texture2D = preload("res://assets/Board/RedHover.png")

@onready var base_rect: TextureRect = $Base
@onready var overlay_rect: TextureRect = $Overlay
@onready var level_label: Label = $LevelLabel

var level_index: int = 0
var _locked: bool = true
var _selected: bool = false

func setup(index: int, is_even: bool, unlocked: bool) -> void:
	level_index = index
	_locked = !unlocked
	_selected = false
	base_rect.texture = base_texture_even if is_even else base_texture_odd
	level_label.text = str(index)
	level_label.visible = unlocked
	overlay_rect.visible = false
	modulate = Color(1, 1, 1, 0.45) if _locked else Color(1, 1, 1, 1)

func set_selected(active: bool) -> void:
	_selected = active
	if _selected:
		overlay_rect.texture = select_texture
		overlay_rect.visible = true
	else:
		overlay_rect.visible = false

func _on_mouse_entered() -> void:
	if _locked or _selected:
		return
	overlay_rect.texture = hover_texture
	overlay_rect.visible = true

func _on_mouse_exited() -> void:
	if _selected:
		return
	overlay_rect.visible = false

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		emit_signal("pressed", self)
