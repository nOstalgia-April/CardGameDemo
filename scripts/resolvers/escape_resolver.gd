extends UnitResolver
class_name EscapeResolver

func resolve(unit: UnitCard) -> bool:
	if !enabled:
		await unit.get_tree().process_frame
		return false
	var cell_context: Dictionary = {
		"cell": null,
	}
	BattleEventBus.emit_signal("unit_cell_requested", unit, cell_context)
	var origin_cell: Cell = cell_context.get("cell", null)
	var neighbors_context: Dictionary = {
		"neighbors": [],
	}
	BattleEventBus.emit_signal("cell_neighbors_requested", origin_cell, neighbors_context)
	var neighbors: Array[Cell] = neighbors_context.get("neighbors", [])
	for cell in neighbors:
		if cell == null or cell.is_occupied():
			continue
		if !_is_in_danger(unit, cell):
			var action_context: Dictionary = {
				"accepted": false,
			}
			BattleEventBus.emit_signal("unit_action_requested", unit, cell, action_context)
			await unit.get_tree().process_frame
			return bool(action_context.get("accepted", false))
	await unit.get_tree().process_frame
	return false

func propose_actions(unit: UnitCard) -> Array:
	if !enabled:
		return []
	var cell_context: Dictionary = {
		"cell": null,
	}
	BattleEventBus.emit_signal("unit_cell_requested", unit, cell_context)
	var origin_cell: Cell = cell_context.get("cell", null)
	var neighbors_context: Dictionary = {
		"neighbors": [],
	}
	BattleEventBus.emit_signal("cell_neighbors_requested", origin_cell, neighbors_context)
	var neighbors: Array[Cell] = neighbors_context.get("neighbors", [])
	for cell in neighbors:
		if cell == null or cell.is_occupied():
			continue
		if !_is_in_danger(unit, cell):
			return [{
				"type": "move",
				"unit": unit,
				"target_cell": cell,
			}]
	return []

func is_in_danger(unit: UnitCard) -> bool:
	var cell_context: Dictionary = {
		"cell": null,
	}
	BattleEventBus.emit_signal("unit_cell_requested", unit, cell_context)
	var cell: Cell = cell_context.get("cell", null)
	return _is_in_danger(unit, cell)

func _is_in_danger(unit: UnitCard, cell: Cell) -> bool:
	var neighbors_context: Dictionary = {
		"neighbors": [],
	}
	BattleEventBus.emit_signal("cell_neighbors_requested", cell, neighbors_context)
	var neighbors: Array[Cell] = neighbors_context.get("neighbors", [])
	for dir in range(4):
		if unit.get_dir_value(dir) > 0:
			continue
		if dir < 0 or dir >= neighbors.size():
			continue
		var neighbor: Cell = neighbors[dir]
		if neighbor == null:
			continue
		var enemy: UnitCard = neighbor.get_unit() as UnitCard
		if enemy == null:
			continue
		if enemy.is_enemy == unit.is_enemy:
			continue
		var opp: int = DirUtils.opposite_dir(dir)
		if enemy.get_dir_value(opp) > 0:
			return true
	return false
