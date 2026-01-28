extends Resource
class_name UnitResolver

@export var enabled: bool = true

func resolve(unit: UnitCard) -> void:
	if !enabled:
		await unit.get_tree().process_frame
		return
	await unit.get_tree().process_frame
