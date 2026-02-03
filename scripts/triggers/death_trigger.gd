extends FlipTrigger
class_name DeathTrigger

func _bind() -> void:
	# DeathTrigger does not respond to user input
	pass

func on_death(context: Dictionary = {}) -> bool:
	if unit == null:
		return false
	# 强制触发翻面效果（即使已翻过）
	var forced_context := context.duplicate()
	forced_context["force"] = true
	unit.flip(forced_context)
	return true
