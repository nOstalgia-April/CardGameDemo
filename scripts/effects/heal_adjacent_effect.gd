extends FlipEffect
class_name HealAdjacentEffect

func apply(target: UnitCard, context: Dictionary = {}) -> void:
	super.apply(target, context)
	if unit == null:
		return
	unit._heal_adjacent_edges()
