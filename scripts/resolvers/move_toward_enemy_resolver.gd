extends UnitResolver
class_name MoveTowardEnemyResolver

func resolve(unit: UnitCard) -> bool:
	if !enabled:
		await unit.get_tree().process_frame
		return false
	var origin_context: Dictionary = {
		"cell": null,
	}
	BattleEventBus.emit_signal("unit_cell_requested", unit, origin_context)
	var origin_cell: Cell = origin_context.get("cell", null)
	var units_context: Dictionary = {
		"units": [],
	}
	var enemy_filter: String = "player" if unit.is_enemy else "enemy"
	BattleEventBus.emit_signal("units_requested", enemy_filter, units_context)
	var enemies: Array = units_context.get("units", [])
	var enemy: UnitCard = _find_best_threat_enemy(unit, origin_cell, enemies)
	if enemy == null:
		return false
	var enemy_context: Dictionary = {
		"cell": null,
	}
	BattleEventBus.emit_signal("unit_cell_requested", enemy, enemy_context)
	var enemy_cell: Cell = enemy_context.get("cell", null)

	var target_cell: Cell = _choose_chase_cell(unit, origin_cell, enemy_cell)
	if target_cell == null:
		return false

	var action_context: Dictionary = {
		"accepted": false,
	}
	BattleEventBus.emit_signal("unit_action_requested", unit, target_cell, action_context)
	await unit.get_tree().process_frame
	return bool(action_context.get("accepted", false))

func propose_actions(unit: UnitCard) -> Array:
	if !enabled:
		return []
	var origin_context: Dictionary = {
		"cell": null,
	}
	BattleEventBus.emit_signal("unit_cell_requested", unit, origin_context)
	var origin_cell: Cell = origin_context.get("cell", null)
	var units_context: Dictionary = {
		"units": [],
	}
	var enemy_filter: String = "player" if unit.is_enemy else "enemy"
	BattleEventBus.emit_signal("units_requested", enemy_filter, units_context)
	var enemies: Array = units_context.get("units", [])
	var enemy: UnitCard = _find_best_threat_enemy(unit, origin_cell, enemies)
	if enemy == null:
		return []
	var enemy_context: Dictionary = {
		"cell": null,
	}
	BattleEventBus.emit_signal("unit_cell_requested", enemy, enemy_context)
	var enemy_cell: Cell = enemy_context.get("cell", null)

	var target_cell: Cell = _choose_chase_cell(unit, origin_cell, enemy_cell)
	if target_cell == null:
		return []

	return [{
		"type": "move",
		"unit": unit,
		"target_cell": target_cell,
	}]

func _dir_from_positions(from_pos: Vector2i, to_pos: Vector2i) -> int:
	var delta: Vector2i = to_pos - from_pos
	if delta == Vector2i(0, -1):
		return 0
	if delta == Vector2i(1, 0):
		return 1
	if delta == Vector2i(0, 1):
		return 2
	if delta == Vector2i(-1, 0):
		return 3
	return -1

func _choose_chase_cell(unit: UnitCard, origin_cell: Cell, enemy_cell: Cell) -> Cell:
	var origin_pos: Vector2i = origin_cell.get_pos()
	var enemy_pos: Vector2i = enemy_cell.get_pos()
	var current_dist: int = abs(origin_pos.x - enemy_pos.x) + abs(origin_pos.y - enemy_pos.y)
	var neighbors_context: Dictionary = {
		"neighbors": [],
	}
	BattleEventBus.emit_signal("cell_neighbors_requested", origin_cell, neighbors_context)
	var neighbors: Array[Cell] = neighbors_context.get("neighbors", [])
	var best_cell: Cell = null
	var best_dist: int = current_dist
	var best_threat_cell: Cell = null
	var best_threat_dist: int = current_dist
	for cell in neighbors:
		if cell == null or cell.is_occupied():
			continue
		var pos: Vector2i = cell.get_pos()
		var dist: int = abs(pos.x - enemy_pos.x) + abs(pos.y - enemy_pos.y)
		if dist >= current_dist:
			continue
		var threat_dir: int = _dir_from_positions(pos, enemy_pos)
		if threat_dir >= 0 and dist == 1:
			var atk_value: int = unit.get_dir_value(threat_dir)
			if atk_value <= 0:
				continue
			if dist < best_threat_dist:
				best_threat_dist = dist
				best_threat_cell = cell
		if dist < best_dist:
			best_dist = dist
			best_cell = cell
	return best_threat_cell if best_threat_cell != null else best_cell

func _find_best_threat_enemy(unit: UnitCard, origin_cell: Cell, enemies: Array) -> UnitCard:
	if enemies.is_empty():
		return null
	var origin_pos: Vector2i = origin_cell.get_pos()
	var best_enemy: UnitCard = null
	var best_dist: int = 1_000_000
	var best_threat_enemy: UnitCard = null
	var best_threat_dist: int = 1_000_000
	for enemy in enemies:
		var enemy_context: Dictionary = {
			"cell": null,
		}
		BattleEventBus.emit_signal("unit_cell_requested", enemy, enemy_context)
		var enemy_cell: Cell = enemy_context.get("cell", null)
		var enemy_pos: Vector2i = enemy_cell.get_pos()
		var dist: int = abs(origin_pos.x - enemy_pos.x) + abs(origin_pos.y - enemy_pos.y)
		var threat_cell: Cell = _choose_chase_cell(unit, origin_cell, enemy_cell)
		if threat_cell != null:
			var threat_pos: Vector2i = threat_cell.get_pos()
			var threat_dist: int = abs(threat_pos.x - enemy_pos.x) + abs(threat_pos.y - enemy_pos.y)
			if threat_dist == 1 and threat_dist < best_threat_dist:
				best_threat_dist = threat_dist
				best_threat_enemy = enemy
		if dist < best_dist:
			best_dist = dist
			best_enemy = enemy
	return best_threat_enemy if best_threat_enemy != null else best_enemy
