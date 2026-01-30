extends Control

func _on_start_pressed() -> void:
	BattleEventBus.go("battle")
