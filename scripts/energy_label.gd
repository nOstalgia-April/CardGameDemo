extends Label

@export var turn_manager_path: NodePath
@onready var turn_manager: TurnManager = get_node(turn_manager_path) as TurnManager
@export var format_text: String = "行动点：%d/%d"

func _ready() -> void:
	var cb: Callable = Callable(self, "_on_resources_changed")
	if !turn_manager.is_connected("resources_changed", cb):
		turn_manager.connect("resources_changed", cb)
	_sync_from_manager()

func _sync_from_manager() -> void:
	var energy_val: int = int(turn_manager.energy)
	var energy_cap_val: int = int(turn_manager.energy_cap)
	var flips_val: int = int(turn_manager.flips_left)
	_on_resources_changed(energy_val, energy_cap_val, flips_val)

func _on_resources_changed(energy: int, energy_cap: int, _flips_left: int) -> void:
	text = format_text % [energy, energy_cap]
