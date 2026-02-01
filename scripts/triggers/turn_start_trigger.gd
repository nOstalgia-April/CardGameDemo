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
	# Only trigger for enemies
	if !unit.is_enemy:
		return
	
	print("[TurnStartTrigger] Triggered for unit: ", unit.name, " (", unit.display_name, ")")
	unit.call("flip")
