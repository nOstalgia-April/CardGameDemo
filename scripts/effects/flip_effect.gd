extends RefCounted
class_name FlipEffect

var unit: UnitCard = null
var persistent: bool = false

func apply(target: UnitCard, context: Dictionary = {}) -> void:
	unit = target

func cleanup() -> void:
	unit = null
