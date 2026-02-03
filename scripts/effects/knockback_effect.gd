extends FlipEffect
class_name KnockbackEffect

func _init() -> void:
	persistent = true

func apply(target: UnitCard, context: Dictionary = {}) -> void:
	super.apply(target, context)
	if unit == null:
		return
	BattleEventBus.damage_applied.connect(_on_damage_applied)
	unit.tree_exiting.connect(_on_unit_exiting)

func cleanup() -> void:
	if BattleEventBus.damage_applied.is_connected(_on_damage_applied):
		BattleEventBus.damage_applied.disconnect(_on_damage_applied)
	if unit != null and unit.tree_exiting.is_connected(_on_unit_exiting):
		unit.tree_exiting.disconnect(_on_unit_exiting)
	super.cleanup()

func _on_unit_exiting() -> void:
	cleanup()

func _on_damage_applied(attacker: Node, target: Node, dir: int, _value: int, _context: Dictionary) -> void:
	if unit == null:
		return
	if _context.get("knockback_domino", false):
		return
	if attacker != unit and target != unit:
		return
	var pushed: UnitCard = target as UnitCard
	if pushed == null:
		return
	var knock_ctx: Dictionary = {"accepted": false}
	BattleEventBus.emit_signal("unit_knockback_requested", pushed, dir, knock_ctx)
