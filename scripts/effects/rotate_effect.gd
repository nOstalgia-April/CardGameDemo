extends FlipEffect
class_name RotateEffect

func apply(target: UnitCard, context: Dictionary = {}) -> void:
	super.apply(target, context)
	if unit == null:
		return
	unit.rotate_numbers(true)
	unit._rotate_adjacent_units(false)
