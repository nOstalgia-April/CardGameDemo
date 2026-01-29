extends Control

@export_group("Refs")
@export var turn_manager_path: NodePath
@export_group("")
@onready var turn_manager: TurnManager = get_node_or_null(turn_manager_path) as TurnManager

func request_end_turn() -> void:
	turn_manager.end_turn()
