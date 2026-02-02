extends FlipTrigger
class_name DeathTrigger

func _bind() -> void:
	# DeathTrigger does not respond to user input
	pass

func on_death(context: Dictionary = {}) -> bool:
	if unit == null:
		return false
	# Force reset flipped state to allow transformation even if unit was already flipped
	unit.set_flipped(false) 
	unit.flip(context)
	return true
