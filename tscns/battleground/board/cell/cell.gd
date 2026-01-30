extends Control
class_name Cell

enum CellState { HIDDEN, AVAILABLE, VISITED }

@export_group("Visual")
@export var color_hidden: Color = Color(0, 0, 0, 0.6)
@export var color_available: Color = Color(1.0, 1.0, 1.0, 0.231)
@export var color_visited: Color = Color(1.0, 1.0, 1.0, 0.502)
@export var highlight_color: Color = Color(1, 1, 1, 0.9)

@export_group("Unit")
@export var unit_scene: PackedScene = preload("res://tscns/battleground/board/unitcard/unit_card.tscn")
@export var unit_z_index: int = 5

@export_group("")
var state: CellState = CellState.AVAILABLE
@onready var fog_layer: ColorRect = $Root/FogLayer
@onready var highlight: Panel = $Root/Highlight
@onready var occupant_slot: Control = $Root/OccupantSlot
@onready var input_button: Button = $Root/Input
var visited_by_player: bool = false

func _ready() -> void:
	add_to_group("cells")
	_set_state_internal(state)
	if input_button != null:
		input_button.pressed.connect(_on_input_pressed)

func set_state(new_state: CellState) -> void:
	state = new_state
	_set_state_internal(state)

func mark_visited() -> void:
	visited_by_player = true
	set_state(CellState.VISITED)

func is_visited_by_player() -> bool:
	return visited_by_player

func place_card(card: Control) -> bool:
	print("放置信号发出")
	var context: Dictionary = {
		"accepted": false,
	}
	BattleEventBus.emit_signal("place_card_requested", card, self, context)
	return bool(context.get("accepted", false))

func remove_unit() -> UnitCard:
	if occupant_slot.get_child_count() == 0:
		return null
	var unit: UnitCard = occupant_slot.get_child(0) as UnitCard
	if unit != null:
		occupant_slot.remove_child(unit)
	return unit

func get_pos() -> Vector2i:
	if has_meta("grid_x") and has_meta("grid_y"):
		return Vector2i(int(get_meta("grid_x")), int(get_meta("grid_y")))
	return Vector2i(-1, -1)

func set_clickable(enabled: bool) -> void:
	if input_button == null:
		return
	input_button.disabled = !enabled
	input_button.mouse_filter = Control.MOUSE_FILTER_STOP if enabled else Control.MOUSE_FILTER_IGNORE

func spawn_unit(display_name: String, n: int, e: int, s: int, w: int, is_enemy: bool) -> bool:
	if occupant_slot.get_child_count() > 0:
		return false
	if unit_scene == null:
		return false

	var unit: UnitCard = unit_scene.instantiate() as UnitCard
	if unit == null:
		return false
	occupant_slot.add_child(unit)
	call_deferred("_fit_unit_to_slot", unit)
	_ensure_unit_z(unit)

	unit.set_card_data(display_name, n, e, s, w, is_enemy)
	return true

func spawn_unit_numbers(display_name: String, numbers: DirectionNumbers, is_enemy: bool) -> bool:
	print('触发')
	return spawn_unit(
		display_name,
		numbers.get_value("n"),
		numbers.get_value("e"),
		numbers.get_value("s"),
		numbers.get_value("w"),
		is_enemy
	)

func place_existing_unit(unit: UnitCard, defer_fit: bool = true) -> bool:
	if occupant_slot.get_child_count() > 0:
		return false
	if unit.get_parent() == null:
		occupant_slot.add_child(unit)
	else:
		unit.reparent(occupant_slot)
	if defer_fit:
		call_deferred("_fit_unit_to_slot", unit)
	else:
		_fit_unit_to_slot(unit)
	_ensure_unit_z(unit)
	return true

func get_unit() -> Control:
	if occupant_slot.get_child_count() == 0:
		return null
	return occupant_slot.get_child(0) as Control

func is_occupied() -> bool:
	return occupant_slot.get_child_count() > 0

func set_highlight(active: bool, color: Color = highlight_color) -> void:
	if !is_instance_valid(highlight):
		return
	highlight.visible = active
	if active:
		var style: StyleBoxFlat = StyleBoxFlat.new()
		style.draw_center = false
		style.border_width_left = 4
		style.border_width_top = 4
		style.border_width_right = 4
		style.border_width_bottom = 4
		style.border_color = color
		highlight.add_theme_stylebox_override("panel", style)

func _fit_unit_to_slot(unit: Control) -> void:
	var slot_size: Vector2 = occupant_slot.size
	if slot_size.x <= 0.0 or slot_size.y <= 0.0:
		return
	var base_size: Vector2 = unit.custom_minimum_size
	if base_size.x <= 0.0 or base_size.y <= 0.0:
		base_size = unit.size
	if base_size.x <= 0.0 or base_size.y <= 0.0:
		return

	unit.set_anchors_preset(Control.PRESET_TOP_LEFT)
	unit.size = base_size

	unit.scale = Vector2.ONE
	unit.position = (slot_size - base_size) * 0.5

func _ensure_unit_z(unit: CanvasItem) -> void:
	unit.z_as_relative = true
	if unit.z_index < unit_z_index:
		unit.z_index = unit_z_index

func _set_state_internal(new_state: CellState) -> void:
	if !is_instance_valid(fog_layer):
		return
	match new_state:
		CellState.HIDDEN:
			fog_layer.color = color_hidden
		CellState.AVAILABLE:
			fog_layer.color = color_available
		CellState.VISITED:
			fog_layer.color = color_visited

func _on_input_pressed() -> void:
	BattleEventBus.emit_signal("cell_pressed", self, {})
