extends UnitResolver
class_name AdjacentAttackResolver

func resolve(unit: UnitCard) -> void:
	if !enabled:
		await unit.get_tree().process_frame
		return
	if unit == null:
		return
	for i in range(4):
		if unit.get_dir_value(i) <= 0:
			continue
		unit.attack(i, true)
	await unit.get_tree().process_frame
