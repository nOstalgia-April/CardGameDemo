extends Control

signal end_turn_requested

func _on_button_pressed() -> void:
	print('下个回合')
	emit_signal("end_turn_requested")
