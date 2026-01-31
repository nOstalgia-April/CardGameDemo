extends Node

var max_unlocked_level: int = 1
var current_level_index: int = 1

func set_current_level(level_index: int) -> void:
	current_level_index = max(1, level_index)

func unlock_next_level(completed_level_index: int) -> void:
	if completed_level_index >= max_unlocked_level:
		max_unlocked_level = completed_level_index + 1
