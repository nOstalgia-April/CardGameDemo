extends FlipTrigger
class_name OnPlaceFlipTrigger

func _bind() -> void:
	pass

func on_placed(context: Dictionary = {}) -> void:
	if !unit.is_enemy and !unit.turn_manager.use_flip():
		return
	await unit.flip(context)
