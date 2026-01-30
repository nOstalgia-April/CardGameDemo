extends Resource
class_name UnitResolver

@export var enabled: bool = true

func resolve(unit: UnitCard) -> bool:
	if !enabled:
		await unit.get_tree().process_frame
		return false
	await unit.get_tree().process_frame
	return false

func propose_actions(_unit: UnitCard) -> Array:
	return []
