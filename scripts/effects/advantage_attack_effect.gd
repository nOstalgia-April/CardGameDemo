extends FlipEffect
class_name AdvantageAttackEffect

func apply(target: UnitCard, context: Dictionary = {}) -> void:
	super.apply(target, context)
	await execute(target)

func execute(unit: UnitCard) -> bool:
	# 复用 AdjacentAttackResolver 的逻辑
	var resolver: AdjacentAttackResolver = AdjacentAttackResolver.new()
	# 强制开启优势攻击
	resolver.advantage = true
	
	# 手动调用 resolver.resolve
	# 注意：Resolver 通常设计用于 TurnManager，但这里的逻辑是通用的
	var result: bool = await resolver.resolve(unit)
	
	# Resolver 是 RefCounted (UnitResolver extends RefCounted usually?) or Node?
	# UnitResolver is likely a RefCounted or custom class.
	# If it's a Node and not added to tree, creating it via new() is fine if it doesn't access tree features immediately.
	# AdjacentAttackResolver uses unit.get_tree() in line 8 and 44.
	# So we need to ensure unit is in tree (it is).
	
	return result
