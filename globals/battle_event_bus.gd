extends Node

signal unit_placed(unit: Node, cell: Node, context: Dictionary)
signal unit_moved(unit: Node, from_cell: Node, to_cell: Node, context: Dictionary)
signal attack_started(attacker: Node, target: Node, dir: int, context: Dictionary)
signal attack_anim_finished(attacker: Node, dir: int, context: Dictionary)
signal damage_applied(attacker: Node, target: Node, dir: int, value: int, context: Dictionary)
signal unit_died(unit: Node, killer: Node, dir: int, context: Dictionary)
signal turn_started(turn_index: int, context: Dictionary)
signal turn_ended(turn_index: int, context: Dictionary)
signal resource_changed(energy: int, flips: int, context: Dictionary)

signal cell_visibility_changed(cell: Node, state: int)
signal flip_used(unit: Node, context: Dictionary)
signal effect_triggered(effect_id: String, unit: Node, context: Dictionary)
signal screen_shake_requested(intensity: float, duration: float, context: Dictionary)

signal place_card_requested(card: Node, cell: Node, context: Dictionary)
signal cell_pressed(cell: Node, context: Dictionary)
signal unit_action_requested(unit: Node, target_cell: Node, context: Dictionary)
signal unit_attack_requested(unit: Node, dir: int, advantage: bool, context: Dictionary)
signal unit_cell_requested(unit: Node, context: Dictionary)
signal unit_knockback_requested(unit: Node, dir: int, context: Dictionary)
signal cell_neighbors_requested(cell: Node, context: Dictionary)
signal units_requested(filter: Variant, context: Dictionary)
signal available_cells_requested(cells: Array, context: Dictionary)
signal clear_available_cells_requested(context: Dictionary)
signal request_scene(scene_key: String, payload: Dictionary)
signal battle_victory(context: Dictionary)
signal battle_defeated(context: Dictionary)

func _ready() -> void:
	add_to_group("battle_event_bus")
	pass

func go(scene_key: String, payload: Dictionary = {}) -> void:
	emit_signal("request_scene", scene_key, payload)
