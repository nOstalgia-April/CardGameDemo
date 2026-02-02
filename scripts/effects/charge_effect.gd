extends FlipEffect
class_name ChargeEffect

const AdjacentAttackResolverScript = preload("res://scripts/resolvers/adjacent_attack_resolver.gd")

func apply(target: UnitCard, context: Dictionary = {}) -> void:
	super.apply(target, context)
	if unit == null:
		return
	unit.attacks_left = 0
	var resolver: AdjacentAttackResolver = AdjacentAttackResolverScript.new()
	resolver.advantage = true
	await resolver.resolve(unit)
	await unit.get_tree().process_frame
