extends UnitResolver
class_name AdjacentAttackResolver

var advantage: bool = true

func resolve(unit: UnitCard) -> bool:
	if !enabled:
		await unit.get_tree().process_frame
		return false
	var cell_context: Dictionary = {
		"cell": null,
	}
	BattleEventBus.emit_signal("unit_cell_requested", unit, cell_context) # direct cell query (was helper)
	var attacker_cell: Cell = cell_context.get("cell", null)
	var neighbors_context: Dictionary = {
		"neighbors": [],
	}
	BattleEventBus.emit_signal("cell_neighbors_requested", attacker_cell, neighbors_context) # direct neighbor query (was helper)
	var neighbors: Array[Cell] = neighbors_context.get("neighbors", [])
	var triggered: bool = false
	for i in range(4):
		if unit.get_dir_value(i) <= 0:
			continue
		if i < 0 or i >= neighbors.size():
			continue
		var target_cell: Cell = neighbors[i]
		if target_cell == null:
			continue
		if target_cell.get_unit() == null:
			continue
		var attack_context: Dictionary = {
			"accepted": false,
		}
		BattleEventBus.emit_signal("unit_attack_requested", unit, i, advantage, attack_context) # direct attack request (was helper)
		if bool(attack_context.get("accepted", false)):
			triggered = true
	await unit.get_tree().process_frame
	return triggered

func propose_actions(unit: UnitCard) -> Array:
	if !enabled:
		return []
	var cell_context: Dictionary = {
		"cell": null,
	}
	BattleEventBus.emit_signal("unit_cell_requested", unit, cell_context) # direct cell query (was helper)
	var attacker_cell: Cell = cell_context.get("cell", null)
	var neighbors_context: Dictionary = {
		"neighbors": [],
	}
	BattleEventBus.emit_signal("cell_neighbors_requested", attacker_cell, neighbors_context) # direct neighbor query (was helper)
	var neighbors: Array[Cell] = neighbors_context.get("neighbors", [])
	var actions: Array = []
	for i in range(4):
		if unit.get_dir_value(i) <= 0:
			continue
		if i < 0 or i >= neighbors.size():
			continue
		var target_cell: Cell = neighbors[i]
		if target_cell == null:
			continue
		if target_cell.get_unit() == null:
			continue
		actions.append({
			"type": "attack",
			"unit": unit,
			"dir": i,
			"advantage": advantage,
		})
	return actions
