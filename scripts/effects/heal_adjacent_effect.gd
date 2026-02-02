extends FlipEffect
class_name HealAdjacentEffect

func apply(target: UnitCard, context: Dictionary = {}) -> void:
	super.apply(target, context)
	if unit == null:
		return
	unit.heal_adjacent_units()
