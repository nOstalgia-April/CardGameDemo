extends Control

@export_group("Refs")
@export var turn_manager: TurnManager
@export_group("")

@onready var texture_button: TextureButton = %NextTurn

func _ready() -> void:
	_bind_event_bus()
	texture_button.mouse_entered.connect(_on_texture_button_mouse_entered)
	texture_button.mouse_exited.connect(_on_texture_button_mouse_exited)

func _on_button_pressed() -> void:
	print("下个回合")
	turn_manager.end_turn()

func _bind_event_bus() -> void:
	BattleEventBus.turn_started.connect(_on_turn_started)


func _on_turn_started(turn_index: int, _context: Dictionary) -> void:
	texture_button.visible = turn_index > 1

func _on_texture_button_pressed() -> void:
	print("下个回合")
	SoundManager.play_sfx("ComputerClick")
	turn_manager.end_turn()
	pass # Replace with function body.

func _on_texture_button_mouse_entered() -> void:
	SoundManager.request_loop_sfx("ComputerHover", "TurnEndButton", true)

func _on_texture_button_mouse_exited() -> void:
	SoundManager.request_loop_sfx("ComputerHover", "TurnEndButton", false)
