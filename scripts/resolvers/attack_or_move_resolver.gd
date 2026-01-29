extends UnitResolver
class_name AttackOrMoveResolver

@export_group("Resolvers")
@export var attack_resolver: AdjacentAttackResolver
@export var move_resolver: MoveTowardEnemyResolver
@export var escape_resolver: EscapeResolver

@export_group("Debug")
@export var debug_log: bool = true
@export_group("")

func resolve(unit: UnitCard) -> bool:
	if debug_log:
		print("[AOM] resolve start unit=", unit, " enemy=", unit.is_enemy)
	if attack_resolver == null:
		attack_resolver = AdjacentAttackResolver.new()
	if move_resolver == null:
		move_resolver = MoveTowardEnemyResolver.new()
	if escape_resolver == null:
		escape_resolver = EscapeResolver.new()

	var in_danger: bool = escape_resolver.is_in_danger(unit)
	if debug_log:
		print("[AOM] in_danger=", in_danger)
	if in_danger:
		var escaped: bool = await escape_resolver.resolve(unit)
		if debug_log:
			print("[AOM] escape_resolve=", escaped)
		if escaped:
			return true
	var attacked: bool = await attack_resolver.resolve(unit)
	if debug_log:
		print("[AOM] attack_resolve=", attacked)
	if attacked:
		return true
	var moved: bool = await move_resolver.resolve(unit)
	if debug_log:
		print("[AOM] move_resolve=", moved)
	return moved

func propose_actions(unit: UnitCard) -> Array:
	if attack_resolver == null:
		attack_resolver = AdjacentAttackResolver.new()
	if move_resolver == null:
		move_resolver = MoveTowardEnemyResolver.new()
	if escape_resolver == null:
		escape_resolver = EscapeResolver.new()
	var in_danger: bool = escape_resolver.is_in_danger(unit)
	if debug_log:
		print("[AOM] propose in_danger=", in_danger)
	if in_danger:
		var escape_actions: Array = escape_resolver.propose_actions(unit)
		if debug_log:
			print("[AOM] escape_actions=", escape_actions.size())
		if escape_actions.size() > 0:
			return escape_actions
	var attacks: Array = attack_resolver.propose_actions(unit)
	if debug_log:
		print("[AOM] attack_actions=", attacks.size())
	if attacks.size() > 0:
		return attacks
	var moves: Array = move_resolver.propose_actions(unit)
	if debug_log:
		print("[AOM] move_actions=", moves.size())
	return moves
