extends Control

signal confirm_pressed

@export_group("Refs")
@export var turn_manager: TurnManager
@export_group("")

enum Mode { NEXT_TURN, CONFIRM }

@export_group("Mode")
@export var mode: Mode = Mode.NEXT_TURN
@export_group("")

@onready var texture_button: TextureButton = %NextTurn
@onready var _next_turn_textures: Dictionary = {
	"normal": preload("res://assets/UI/Computer/next_turn/ui_nextturn.png"),
	"hover": preload("res://assets/UI/Computer/next_turn/ui_nextturn_hover.png"),
	"pressed": preload("res://assets/UI/Computer/next_turn/ui_nextturn_press.png"),
}
@onready var _confirm_textures: Dictionary = {
	"normal": preload("res://assets/UI/Computer/confirm/ui_confirm .png"),
	"hover": preload("res://assets/UI/Computer/confirm/ui_confirm_hover.png"),
	"pressed": preload("res://assets/UI/Computer/confirm/ui_confirm_press.png"),
}

func _ready() -> void:
	_bind_event_bus()
	texture_button.mouse_entered.connect(_on_texture_button_mouse_entered)
	texture_button.mouse_exited.connect(_on_texture_button_mouse_exited)
	# 默认隐藏按钮，由turn_hint_controller控制显示
	texture_button.visible = false
	_apply_mode()

func _on_button_pressed() -> void:
	print("下个回合")
	turn_manager.end_turn()

func _bind_event_bus() -> void:
	BattleEventBus.turn_started.connect(_on_turn_started)


func _on_turn_started(turn_index: int, _context: Dictionary) -> void:
	if mode == Mode.NEXT_TURN:
		# 第一回合隐藏按钮，由turn_hint_controller控制
		texture_button.visible = turn_index > 1

func _on_texture_button_pressed() -> void:
	SoundManager.play_sfx("ComputerClick")
	if mode == Mode.CONFIRM:
		emit_signal("confirm_pressed")
		return
	print("下个回合")
	turn_manager.end_turn()

func _on_texture_button_mouse_entered() -> void:
	SoundManager.request_loop_sfx("ComputerHover", "TurnEndButton", true)

func _on_texture_button_mouse_exited() -> void:
	SoundManager.request_loop_sfx("ComputerHover", "TurnEndButton", false)

func set_mode(new_mode: Mode) -> void:
	if mode == new_mode:
		return
	mode = new_mode
	_apply_mode()

func _apply_mode() -> void:
	var textures: Dictionary = _next_turn_textures if mode == Mode.NEXT_TURN else _confirm_textures
	texture_button.texture_normal = textures.get("normal", texture_button.texture_normal)
	texture_button.texture_hover = textures.get("hover", texture_button.texture_hover)
	texture_button.texture_pressed = textures.get("pressed", texture_button.texture_pressed)

func show_button() -> void:
	texture_button.visible = true

func hide_button() -> void:
	texture_button.visible = false
