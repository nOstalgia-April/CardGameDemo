extends FlipTrigger
class_name ParityChangeTrigger

var _last_parity: int = -1

func _bind() -> void:
	if unit.has_signal("values_changed"):
		unit.connect("values_changed", _on_values_changed)
	
	# Init parity
	_update_parity(false)

func cleanup() -> void:
	if is_instance_valid(unit) and unit.has_signal("values_changed"):
		if unit.is_connected("values_changed", _on_values_changed):
			unit.disconnect("values_changed", _on_values_changed)
	super.cleanup()

func _on_values_changed(_unit: Node) -> void:
	_update_parity(true)

func _update_parity(check_change: bool) -> void:
	if !is_instance_valid(unit):
		return
		
	var sum_val: int = 0
	var nums = unit.get_direction_numbers()
	if nums:
		sum_val = nums.get_value("n") + nums.get_value("e") + nums.get_value("s") + nums.get_value("w")
	
	var current_parity: int = sum_val % 2
	
	if check_change:
		if _last_parity != -1 and current_parity != _last_parity:
			# Parity changed!
			print("[ParityChangeTrigger] Parity changed from ", _last_parity, " to ", current_parity, ". Flipping unit.")
			unit.call("flip")
	
	_last_parity = current_parity
