extends UnitResolver
class_name RangedAttackResolver

var advantage: bool = true

func resolve(unit: UnitCard) -> bool:
	if !enabled:
		await unit.get_tree().process_frame
		return false
		
	var triggered: bool = false
	for i in range(4):
		if unit.get_dir_value(i) <= 0:
			continue
			
		var attack_context: Dictionary = {
			"accepted": false,
			"ranged": true
		}
		BattleEventBus.emit_signal("unit_attack_requested", unit, i, advantage, attack_context)
		if bool(attack_context.get("accepted", false)):
			triggered = true
			await BattleEventBus.attack_anim_finished
			
	await unit.get_tree().process_frame
	return triggered
