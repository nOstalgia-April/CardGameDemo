extends Control
class_name UnitCard

signal died(unit: Node, killer: Node, dir: int)

@export var is_enemy: bool = false
@export var player_color: Color = Color(0.2, 0.45, 1.0, 0.35)
@export var enemy_color: Color = Color(1.0, 0.25, 0.25, 0.35)
@export var hover_border_color: Color = Color(1, 1, 1, 1)
@export var enemy_border_color: Color = Color(1, 0.2, 0.2, 1)
@export var border_width: int = 4
@export var custom_resolver: UnitResolver
@export var board: Board
@export var max_attacks_per_turn: int = 1

@onready var card_bg: Panel = $CardBg
@onready var color_rect: ColorRect = $CardBg/ColorRect
@onready var hover_border: Panel = $HoverBorder
@onready var dir_n: Control = $DirNums/N
@onready var dir_e: Control = $DirNums/E
@onready var dir_s: Control = $DirNums/S
@onready var dir_w: Control = $DirNums/W

enum Dir { N, E, S, W }

var value_n: int = 0
var value_e: int = 0
var value_s: int = 0
var value_w: int = 0

var _hover_active: bool = false
var _enemy_highlight_active: bool = false
var _selecting: bool = false
var _neighbor_cells: Array[Cell] = []
var _dead: bool = false
var attacks_left: int = 0

func _ready() -> void:
	_apply_faction_color()
	_setup_border()
	_update_border()
	_reset_attacks()
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func set_is_enemy(flag: bool) -> void:
	is_enemy = flag
	_apply_faction_color()
	_update_border()
	_reset_attacks()

func is_enemy_unit() -> bool:
	return is_enemy

func set_enemy_highlight(active: bool) -> void:
	_enemy_highlight_active = active
	_update_border()

func set_card_data(display_name: String, n: int, e: int, s: int, w: int, enemy: bool = false) -> void:
	is_enemy = enemy
	_apply_faction_color()
	_update_border()
	_reset_attacks()
	_apply_dir_value(Dir.N, n)
	_apply_dir_value(Dir.E, e)
	_apply_dir_value(Dir.S, s)
	_apply_dir_value(Dir.W, w)

func take_damage(dir: int, attacker: Node, value: int) -> Dictionary:
	var def_before: int = get_dir_value(dir)
	if def_before <= 0 and value > 0:
		die(attacker, dir)
		return {
			"def_before": def_before,
			"def_after": def_before,
			"damage": value,
			"attacker": attacker,
			"destroyed": true,
		}
	var def_after: int = max(0, def_before - value)
	_apply_dir_value(dir, def_after)
	return {
		"def_before": def_before,
		"def_after": def_after,
		"damage": value,
		"attacker": attacker,
		"destroyed": false,
	}

func attack(dir: int, advantage: bool = false) -> void:
	if !is_enemy:
		if attacks_left <= 0:
			return
		attacks_left -= 1
	board.resolve_attack_dir(self, dir, advantage)

func die(killer: Node, dir: int) -> void:
	if _dead:
		return
	_dead = true
	emit_signal("died", self, killer, dir)

func resolve_turn() -> void:
	if custom_resolver != null:
		await custom_resolver.resolve(self)
	else:
		await get_tree().process_frame

func set_board(value: Board) -> void:
	board = value
	var cb: Callable = Callable(self, "_on_turn_started")
	if !board.turn_manager.is_connected("turn_started", cb):
		board.turn_manager.connect("turn_started", cb)

func _on_turn_started(_turn_index: int) -> void:
	_reset_attacks()

func _reset_attacks() -> void:
	if is_enemy:
		attacks_left = -1
	else:
		attacks_left = max(0, max_attacks_per_turn)


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

func _apply_dir_value(dir: int, value: int) -> void:
	match dir:
		Dir.N:
			value_n = value
			if dir_n != null:
				dir_n.visible = value_n > 0
			_set_dir_value(dir_n, value)
		Dir.E:
			value_e = value
			if dir_e != null:
				dir_e.visible = value_e > 0
			_set_dir_value(dir_e, value)
		Dir.S:
			value_s = value
			if dir_s != null:
				dir_s.visible = value_s > 0
			_set_dir_value(dir_s, value)
		Dir.W:
			value_w = value
			if dir_w != null:
				dir_w.visible = value_w > 0
			_set_dir_value(dir_w, value)

func get_dir_value(dir: int) -> int:
	match dir:
		Dir.N:
			return value_n
		Dir.E:
			return value_e
		Dir.S:
			return value_s
		Dir.W:
			return value_w
	return 0

func set_dir_value(dir: int, value: int) -> void:
	_apply_dir_value(dir, value)

func get_opposite_dir(dir: int) -> int:
	match dir:
		Dir.N:
			return Dir.S
		Dir.E:
			return Dir.W
		Dir.S:
			return Dir.N
		Dir.W:
			return Dir.E
	return Dir.N

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
	_neighbor_cells = _get_available_neighbor_cells()
	board.set_available_cells(_neighbor_cells)
	_update_border()

func _end_select() -> void:
	if !_selecting:
		return
	_selecting = false
	var target_cell: Node = _get_target_cell(_neighbor_cells)
	board.clear_available_cells(false)
	_neighbor_cells.clear()

	if target_cell != null:
		if board.turn_manager.energy < 1:
			_hover_active = _is_mouse_over()
			_update_border()
			board.update_visibility()
			return
		board.turn_manager.spend_energy(1)
		var target: Cell = target_cell as Cell
		if target.is_occupied():
			_handle_attack(target)
		else:
			var from_cell: Node = _get_parent_cell()
			var moved: bool = target.place_existing_unit(self)
			if moved:
				board.on_player_unit_moved(from_cell, target)

	_hover_active = _is_mouse_over()
	_update_border()
	board.update_visibility()

func _handle_attack(target_cell: Cell) -> void:
	board.resolve_attack_on_cell(self, target_cell, false)

func _get_parent_cell() -> Node:
	var node: Node = get_parent()
	while node != null:
		if node.is_in_group("cells"):
			return node
		node = node.get_parent()
	return null

func _get_neighbor_cells() -> Array[Cell]:
	var cell: Node = _get_parent_cell()
	if cell == null:
		return []
	return board.get_neighbor_cells(cell as Cell)

func _get_available_neighbor_cells() -> Array[Cell]:
	var neighbors: Array[Cell] = _get_neighbor_cells()
	if is_enemy:
		return neighbors
	var filtered: Array[Cell] = []
	for i in range(neighbors.size()):
		var cell: Cell = neighbors[i]
		if cell == null:
			continue
		if _cell_has_enemy(cell) and get_dir_value(i) <= 0:
			continue
		filtered.append(cell)
	return filtered

func _cell_has_enemy(cell: Cell) -> bool:
	if cell == null:
		return false
	var unit: UnitCard = cell.get_unit() as UnitCard
	return unit != null and unit.is_enemy_unit()

func _get_target_cell(candidates: Array[Cell]) -> Cell:
	var mouse_pos: Vector2 = get_global_mouse_position()
	for cell in candidates:
		var c: Control = cell as Control
		if c != null and c.get_global_rect().has_point(mouse_pos):
			return cell
	return null

func _is_mouse_over() -> bool:
	return get_global_rect().has_point(get_global_mouse_position())
