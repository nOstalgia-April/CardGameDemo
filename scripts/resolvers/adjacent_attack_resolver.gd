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
		var target_unit: UnitCard = target_cell.get_unit() as UnitCard
		if target_unit == null:
			continue
		
		# Prevent friendly fire: only attack if teams are different
		if target_unit.is_enemy == unit.is_enemy:
			continue
			
		var attack_context: Dictionary = {
			"accepted": false,
		}
		BattleEventBus.emit_signal("unit_attack_requested", unit, i, advantage, attack_context) # direct attack request (was helper)
		if bool(attack_context.get("accepted", false)):
			triggered = true
			await BattleEventBus.attack_anim_finished
	await unit.get_tree().process_frame
	return triggered
