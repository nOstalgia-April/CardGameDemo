extends RefCounted
class_name FlipTrigger

var unit: UnitCard = null

func bind(target: UnitCard) -> void:
	unit = target
	_bind()

func cleanup() -> void:
	if unit.gui_input.is_connected(_on_gui_input):
		unit.gui_input.disconnect(_on_gui_input)
	unit = null

func _bind() -> void:
	unit.gui_input.connect(_on_gui_input)

func _on_gui_input(event: InputEvent) -> void:
	if unit.is_enemy:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		if !unit.turn_manager.use_flip():
			return
		unit.call("flip")

func on_placed(_context: Dictionary = {}) -> void:
	await unit.get_tree().process_frame
