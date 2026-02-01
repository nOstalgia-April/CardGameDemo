extends Node

@export var test_mode: bool = false
@export var max_level: int = 7

var max_unlocked_level: int = 1
var current_level_index: int = 1
var game_cleared: bool = false

func _ready() -> void:
	if test_mode:
		max_unlocked_level = 9

func set_current_level(level_index: int) -> void:
	current_level_index = max(1, level_index)

func unlock_next_level(completed_level_index: int) -> void:
	if completed_level_index >= max_level:
		return
	if completed_level_index >= max_unlocked_level:
		max_unlocked_level = completed_level_index + 1
