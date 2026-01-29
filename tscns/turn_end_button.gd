extends Control

@export_group("Refs")
@export var turn_manager_path: NodePath
@export_group("")

@onready var turn_manager: TurnManager = get_node_or_null(turn_manager_path) as TurnManager
@onready var event_bus = BattleEventBus

func _ready() -> void:
	_bind_event_bus()

func _on_button_pressed() -> void:
	print("下个回合")
	if turn_manager != null:
		turn_manager.end_turn()

func _bind_event_bus() -> void:
	var cb: Callable = Callable(self, "_on_turn_started")
	if !event_bus.is_connected("turn_started", cb):
		event_bus.connect("turn_started", cb)

func _on_turn_started(turn_index: int, _context: Dictionary) -> void:
	visible = turn_index >= 1
