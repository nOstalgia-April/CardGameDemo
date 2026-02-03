extends FlipTrigger
class_name TurnStartTrigger

func _bind() -> void:
	BattleEventBus.connect("turn_started", _on_turn_started)

func cleanup() -> void:
	if BattleEventBus.is_connected("turn_started", _on_turn_started):
		BattleEventBus.disconnect("turn_started", _on_turn_started)
	super.cleanup()

func _on_turn_started(_turn_index: int, _context: Dictionary) -> void:
	if unit == null or !is_instance_valid(unit):
		return
	if !unit.is_enemy:
		return

	var ctx := {"units": []}
	BattleEventBus.emit_signal("units_requested", null, ctx)
	var all_units: Array = ctx.get("units", [])
	for u in all_units:
		print(u.display_name)
		if u.display_name.contains("蜘蛛卵"):
			print(unit.display_name)
			unit.call("flip")
			return
