extends Control

@export var is_enemy: bool = false
@export var player_color: Color = Color(0.2, 0.45, 1.0, 0.35)
@export var enemy_color: Color = Color(1.0, 0.25, 0.25, 0.35)
@export var hover_border_color: Color = Color(1, 1, 1, 1)
@export var enemy_border_color: Color = Color(1, 0.2, 0.2, 1)
@export var border_width: int = 4

@onready var card_bg: Panel = $CardBg
@onready var color_rect: ColorRect = $CardBg/ColorRect
@onready var hover_border: Panel = $HoverBorder
@onready var dir_n: Control = $DirNums/N
@onready var dir_e: Control = $DirNums/E
@onready var dir_s: Control = $DirNums/S
@onready var dir_w: Control = $DirNums/W

var _hover_active: bool = false
var _enemy_highlight_active: bool = false
var _selecting: bool = false
var _neighbor_cells: Array[Node] = []

func _ready() -> void:
	_apply_faction_color()
	_setup_border()
	_update_border()
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func set_is_enemy(flag: bool) -> void:
	is_enemy = flag
	_apply_faction_color()
	_update_border()

func set_enemy_highlight(active: bool) -> void:
	_enemy_highlight_active = active
	_update_border()

func set_card_data(display_name: String, n: int, e: int, s: int, w: int, enemy: bool = false) -> void:
	is_enemy = enemy
	_apply_faction_color()
	_update_border()
	_set_dir_value(dir_n, n)
	_set_dir_value(dir_e, e)
	_set_dir_value(dir_s, s)
	_set_dir_value(dir_w, w)

func _apply_faction_color() -> void:
	if !is_instance_valid(card_bg):
		return
	if card_bg.has_theme_stylebox_override("panel"):
		card_bg.remove_theme_stylebox_override("panel")
	if is_instance_valid(color_rect):
		color_rect.color = enemy_color if is_enemy else player_color

func _setup_border() -> void:
	if !is_instance_valid(hover_border):
		return
	hover_border.visible = false

func _update_border() -> void:
	if !is_instance_valid(hover_border):
		return
	if _enemy_highlight_active:
		hover_border.visible = true
		hover_border.add_theme_stylebox_override("panel", _make_border_style(enemy_border_color))
	elif _hover_active and !is_enemy:
		hover_border.visible = true
		hover_border.add_theme_stylebox_override("panel", _make_border_style(hover_border_color))
	else:
		hover_border.visible = false

func _make_border_style(color: Color) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.draw_center = false
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.border_color = color
	return style

func _set_dir_value(node: Control, value: int) -> void:
	var label: Label = node.get_node("Value") as Label
	if label != null:
		label.text = str(value)

func _on_mouse_entered() -> void:
	if is_enemy:
		return
	_hover_active = true
	_update_border()

func _on_mouse_exited() -> void:
	if _selecting:
		return
	_hover_active = false
	_update_border()

func _gui_input(event: InputEvent) -> void:
	if is_enemy:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_begin_select()
			accept_event()
		else:
			_end_select()
			accept_event()

func _begin_select() -> void:
	if _selecting:
		return
	_selecting = true
	_hover_active = true
	_neighbor_cells = _get_neighbor_cells()
	for cell in _neighbor_cells:
		if cell != null and cell.has_method("set_highlight"):
			cell.call("set_highlight", true)
	_update_border()

func _end_select() -> void:
	if !_selecting:
		return
	_selecting = false
	var target_cell: Node = _get_target_cell(_neighbor_cells)
	for cell in _neighbor_cells:
		if cell != null and cell.has_method("set_highlight"):
			cell.call("set_highlight", false)
	_neighbor_cells.clear()

	if target_cell != null:
		if target_cell.has_method("is_occupied") and bool(target_cell.call("is_occupied")):
			_handle_attack(target_cell)
		elif target_cell.has_method("place_existing_unit"):
			var from_cell: Node = _get_parent_cell()
			var moved: bool = bool(target_cell.call("place_existing_unit", self))
			if moved and from_cell != null:
				if from_cell.has_method("mark_visited"):
					from_cell.call("mark_visited")
				elif from_cell.has_method("set_state"):
					from_cell.call("set_state", 2) # CellState.VISITED

	_hover_active = _is_mouse_over()
	_update_border()

func _handle_attack(target_cell: Node) -> void:
	pass

func _get_parent_cell() -> Node:
	var node: Node = get_parent()
	while node != null:
		if node.is_in_group("cells"):
			return node
		node = node.get_parent()
	return null

func _get_neighbor_cells() -> Array[Node]:
	var board: Node = get_tree().get_first_node_in_group("board")
	if board == null or !board.has_method("get_neighbor_cells"):
		return []
	var cell: Node = _get_parent_cell()
	if cell == null:
		return []
	return board.call("get_neighbor_cells", cell) as Array[Node]

func _get_target_cell(candidates: Array[Node]) -> Node:
	var mouse_pos: Vector2 = get_global_mouse_position()
	for cell in candidates:
		var c: Control = cell as Control
		if c != null and c.get_global_rect().has_point(mouse_pos):
			return cell
	return null

func _is_mouse_over() -> bool:
	return get_global_rect().has_point(get_global_mouse_position())
