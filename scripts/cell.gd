extends Control
class_name Cell

enum CellState { HIDDEN, AVAILABLE, VISITED }

@export var state: CellState = CellState.AVAILABLE
@export var color_hidden: Color = Color(0, 0, 0, 0.6)
@export var color_available: Color = Color(1.0, 1.0, 1.0, 0.231)
@export var color_visited: Color = Color(1.0, 1.0, 1.0, 0.502)
@export var unit_scene: PackedScene
@export var board: Board

@export var highlight_color: Color = Color(1, 1, 1, 0.9)
@onready var fog_layer: ColorRect = $Root/FogLayer
@onready var highlight: Panel = $Root/Highlight
@onready var occupant_slot: Control = $Root/OccupantSlot
var visited_by_player: bool = false

func _ready() -> void:
	add_to_group("cells")
	if unit_scene == null:
		unit_scene = preload("res://tscns/unit_card.tscn")
	_set_state_internal(state)

func set_state(new_state: CellState) -> void:
	state = new_state
	_set_state_internal(state)

func mark_visited() -> void:
	visited_by_player = true
	set_state(CellState.VISITED)

func is_visited_by_player() -> bool:
	return visited_by_player

func place_card(card: Control) -> bool:
	if !board.can_place_on(self):
		return false
	if is_occupied():
		return false
	if board.turn_manager.energy < 1:
		return false
	var data: Dictionary = card.get_card_data() as Dictionary
	var display_name: String = str(data.get("display_name", ""))
	var n: int = int(data.get("n", 0))
	var e: int = int(data.get("e", 0))
	var s: int = int(data.get("s", 0))
	var w: int = int(data.get("w", 0))
	var placed: bool = spawn_unit(display_name, n, e, s, w, false)
	if placed:
		board.turn_manager.spend_energy(1)
	return placed

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
	unit.set_board(board)

	unit.set_card_data(display_name, n, e, s, w, is_enemy)
	if is_enemy and unit.custom_resolver == null:
		unit.custom_resolver = AdjacentAttackResolver.new()
	_connect_unit_signals(unit)
	if is_enemy:
		board.on_enemy_updated()
	else:
		board.on_player_unit_placed(self)
	return true

func place_existing_unit(unit: UnitCard) -> bool:
	if occupant_slot.get_child_count() > 0:
		return false
	if unit == null or !is_instance_valid(unit):
		return false
	if unit.get_parent() != null:
		unit.get_parent().remove_child(unit)
	occupant_slot.add_child(unit)
	call_deferred("_fit_unit_to_slot", unit)
	unit.set_board(board)
	_connect_unit_signals(unit)
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
	if unit == null or !is_instance_valid(unit):
		return
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

	var scale_factor: float = min(slot_size.x / base_size.x, slot_size.y / base_size.y) * 1
	unit.scale = Vector2.ONE * scale_factor
	unit.position = (slot_size - base_size * scale_factor) * 0.5

func _connect_unit_signals(unit: Node) -> void:
	var callable := Callable(board, "on_unit_died")
	if unit.is_connected("died", callable):
		return
	unit.connect("died", callable)

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
