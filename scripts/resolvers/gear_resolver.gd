extends UnitResolver
class_name GearResolver

@export var clockwise_self: bool = true

func resolve(unit: UnitCard) -> bool:
	print("GearResolver")
	if !enabled:
		await unit.get_tree().process_frame
		return false
	
	# Action 1: Rotate self
	unit.rotate_numbers(clockwise_self)
	
	# Wait a frame to ensure logic updates
	await unit.get_tree().process_frame
	
	# Action 2: Rotate neighbors (opposite direction)
	# Reuse UnitCard's built-in method which handles neighbor lookup correctly
	unit._rotate_adjacent_units(!clockwise_self)
			
	await unit.get_tree().process_frame
	return true
