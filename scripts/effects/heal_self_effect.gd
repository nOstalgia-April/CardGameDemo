extends FlipEffect
class_name HealSelfEffect

func apply(target: UnitCard, context: Dictionary = {}) -> void:
	super.apply(target, context)
	if unit == null:
		return
	unit.heal_full()
