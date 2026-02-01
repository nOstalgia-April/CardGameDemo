extends FlipEffect
class_name SwapEffect

signal selection_done

var _board: Board = null
var _target_cells: Array[Cell] = []
var _all_cells: Array[Cell] = []
var _prev_cell_states: Dictionary = {}
var _prev_unit_mouse_filters: Dictionary = {}
var _prev_unit_process_input: Dictionary = {}
var _prev_buttons: Dictionary = {}
var _hand_view: HandView = null
var _prev_hand_mouse_filter: int = Control.MOUSE_FILTER_STOP
var _cleaned: bool = false

func _init() -> void:
	persistent = true

func apply(target: UnitCard, context: Dictionary = {}) -> void:
	super.apply(target, context)
	_board = _find_board()
	_target_cells = _collect_target_cells()
	_lock_input()
	_highlight_targets()
	BattleEventBus.cell_pressed.connect(_on_cell_pressed)
	unit.tree_exiting.connect(_on_unit_exiting)
	selection_done.connect(_on_selection_done)

func cleanup() -> void:
	if _cleaned:
		return
	_cleaned = true
	BattleEventBus.cell_pressed.disconnect(_on_cell_pressed)
	unit.tree_exiting.disconnect(_on_unit_exiting)
	_restore_input()
	_board.clear_available_cells(true)
	super.cleanup()

func _find_board() -> Board:
	return unit.get_tree().get_nodes_in_group("board")[0] as Board

func _collect_target_cells() -> Array[Cell]:
	var cells: Array[Cell] = []
	var units: Array[UnitCard] = _board.find_units()
	for u in units:
		if u == unit:
			continue
		cells.append(_board.get_parent_cell_of_unit(u))
	return cells

func _lock_input() -> void:
	var units: Array[UnitCard] = _board.find_units()
	for u in units:
		_prev_unit_mouse_filters[u] = u.mouse_filter
		_prev_unit_process_input[u] = u.is_processing_input()
		u.mouse_filter = Control.MOUSE_FILTER_IGNORE
		u.set_process_input(false)

	_hand_view = _board.get_parent().get_node("HandView") as HandView
	_prev_hand_mouse_filter = _hand_view.mouse_filter
	_hand_view.mouse_filter = Control.MOUSE_FILTER_IGNORE

	_prev_buttons.clear()
	var buttons: Array = []
	_collect_buttons(unit.get_tree().get_root(), buttons)
	for btn in buttons:
		var b: BaseButton = btn
		_prev_buttons[b] = {
			"disabled": b.disabled,
			"mouse_filter": b.mouse_filter,
		}
		b.disabled = true
		b.mouse_filter = Control.MOUSE_FILTER_IGNORE

	_all_cells.clear()
	var nodes: Array = unit.get_tree().get_nodes_in_group("cells")
	for node in nodes:
		var cell: Cell = node
		_all_cells.append(cell)
		_prev_cell_states[cell] = {
			"disabled": cell.input_button.disabled,
			"mouse_filter": cell.input_button.mouse_filter,
		}
		cell.set_clickable(false)
	for cell in _target_cells:
		cell.set_clickable(true)

func _restore_input() -> void:
	for cell in _all_cells:
		var prev: Dictionary = _prev_cell_states.get(cell, {})
		cell.input_button.disabled = prev.get("disabled", false)
		cell.input_button.mouse_filter = int(prev.get("mouse_filter", Control.MOUSE_FILTER_IGNORE))

	for u in _prev_unit_mouse_filters.keys():
		u.mouse_filter = int(_prev_unit_mouse_filters.get(u, Control.MOUSE_FILTER_STOP))
		if _prev_unit_process_input.has(u):
			u.set_process_input(bool(_prev_unit_process_input.get(u)))

	_hand_view.mouse_filter = _prev_hand_mouse_filter
	for btn in _prev_buttons.keys():
		var data: Dictionary = _prev_buttons.get(btn, {})
		btn.disabled = bool(data.get("disabled", false))
		btn.mouse_filter = int(data.get("mouse_filter", Control.MOUSE_FILTER_STOP))

func _highlight_targets() -> void:
	_board.highlight_cells(_target_cells, Color(1, 1, 1, 0.9), true)

func _collect_buttons(node: Node, out: Array) -> void:
	if node is BaseButton:
		out.append(node)
	for child in node.get_children():
		_collect_buttons(child, out)

func _on_cell_pressed(cell: Cell, _context: Dictionary) -> void:
	if !_target_cells.has(cell):
		return
	unit.swap_ready = true
	_board.try_unit_action(unit, cell, false)
	emit_signal("selection_done")

func _on_unit_exiting() -> void:
	emit_signal("selection_done")

func _on_selection_done() -> void:
	cleanup()
