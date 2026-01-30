extends Control

@export_group("Refs")
@export var turn_manager: TurnManager
@export_group("")

@onready var texture_button: TextureButton = $TextureButton

func _ready() -> void:
	_bind_event_bus()

func _on_button_pressed() -> void:
	print("下个回合")
	turn_manager.end_turn()

func _bind_event_bus() -> void:
	BattleEventBus.turn_started.connect(_on_turn_started)


func _on_turn_started(turn_index: int, _context: Dictionary) -> void:
	texture_button.visible = turn_index > 1

func _on_texture_button_pressed() -> void:
	print("下个回合")
	turn_manager.end_turn()
	pass # Replace with function body.
