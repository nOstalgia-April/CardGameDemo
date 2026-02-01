extends UnitResolver
class_name AttackRangedOrMoveResolver

@export_group("Resolvers")
@export var attack_resolver: RangedAttackResolver
@export var move_resolver: MoveTowardEnemyResolver
@export var escape_resolver: EscapeResolver

@export_group("Debug")
@export var debug_log: bool = true
@export_group("")

func resolve(unit: UnitCard) -> bool:
	if debug_log:
		print("[AROM] resolve start unit=", unit, " enemy=", unit.is_enemy)
	if attack_resolver == null:
		attack_resolver = RangedAttackResolver.new()
	if move_resolver == null:
		move_resolver = MoveTowardEnemyResolver.new()
	if escape_resolver == null:
		escape_resolver = EscapeResolver.new()

	var in_danger: bool = escape_resolver.is_in_danger(unit)
	if debug_log:
		print("[AROM] in_danger=", in_danger)
	if in_danger:
		var escaped: bool = await escape_resolver.resolve(unit)
		if debug_log:
			print("[AROM] escape_resolve=", escaped)
		if escaped:
			return true
			
	var attacked: bool = await attack_resolver.resolve(unit)
	if debug_log:
		print("[AROM] attack_resolve=", attacked)
	if attacked:
		return true
		
	var moved: bool = await move_resolver.resolve(unit)
	if debug_log:
		print("[AROM] move_resolve=", moved)
	return moved
