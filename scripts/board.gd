extends Control
class_name Board

@onready var grid: GridContainer = $GridContainer
var cell_map: Dictionary = {}
var first_placement_done: bool = false
var visible_cells: Dictionary = {}
var available_cells: Array[Cell] = []
@export var enemy_cell_highlight_color: Color = Color(1, 0.2, 0.2, 1)
@export var cleanup_delay: float = 0.0
@export var turn_manager_path: NodePath
@onready var turn_manager: TurnManager = get_node(turn_manager_path) as TurnManager

func on_unit_died(unit: Node, killer: Node, dir: int) -> void:
	if unit == null or !is_instance_valid(unit):
		return
	if cleanup_delay > 0.0:
		var timer: SceneTreeTimer = get_tree().create_timer(cleanup_delay)
		await timer.timeout
	if is_instance_valid(unit):
		unit.queue_free()
	update_visibility()

func resolve_attack_dir(attacker: UnitCard, dir: int, advantage: bool = false) -> void:
	if attacker == null:
		return
	if dir < 0 or dir > 3:
		return
	var attacker_cell: Cell = _find_parent_cell(attacker) as Cell
	if attacker_cell == null:
		return
	var neighbors: Array[Cell] = get_neighbor_cells(attacker_cell)
	var target_cell: Cell = neighbors[dir]
	if target_cell == null:
		return
	var defender: UnitCard = _get_unit_from_cell(target_cell)
	if defender == null:
		return
	var atk_value: int = attacker.get_dir_value(dir)
	if atk_value <= 0:
		return
	var opp: int = get_opposite_dir(dir)
	var def_value: int = defender.get_dir_value(opp)
	print("resolve_attack_dir",
		"dir=", dir,
		"opp=", opp,
		"atk_value=", atk_value,
		"def_value=", def_value,
		"attacker_cell=", attacker_cell,
		"defender_cell=", target_cell
	)
	# 播放攻击方的撞击动画
	attacker.play_bump_animation(dir)
	# 触发屏幕震动效果
	_trigger_screen_shake()
	defender.take_damage(opp, attacker, atk_value)
	if !advantage:
		attacker.take_damage(dir, defender, def_value)

# 触发屏幕震动效果
func _trigger_screen_shake() -> void:
	var battle_node: Node = get_node("/root/Battle")
	if battle_node and battle_node.has_method("trigger_screen_shake"):
		# 使用默认参数触发震动
		battle_node.trigger_screen_shake(0.0, 0.0)

func resolve_attack_on_cell(attacker: UnitCard, target_cell: Cell, advantage: bool = false) -> void:
	if attacker == null or target_cell == null:
		return
	var attacker_cell: Cell = _find_parent_cell(attacker) as Cell
	if attacker_cell == null:
		return
	var dir: int = _get_dir_between_cells(attacker_cell, target_cell)
	if dir < 0:
		return
	resolve_attack_dir(attacker, dir, advantage)

func get_opposite_dir(dir: int) -> int:
	match dir:
		0: # N
			return 2 # S
		1: # E
			return 3 # W
		2: # S
			return 0 # N
		3: # W
			return 1 # E
	return 0

func _get_dir_between_cells(from_cell: Cell, to_cell: Cell) -> int:
	var neighbors: Array[Cell] = get_neighbor_cells(from_cell)
	return neighbors.find(to_cell)

func _find_parent_cell(node: Node) -> Cell:
	var current: Node = node
	while current != null:
		if current.is_in_group("cells"):
			return current as Cell
		current = current.get_parent()
	return null

func _ready() -> void:
	add_to_group("board")
	_index_cells()
	turn_manager.request_turn_resolution.connect(_on_request_turn_resolution)
	update_visibility()

func _on_request_turn_resolution(units: Array) -> void:
	await resolve_turn(units)
	turn_manager.turn_resolution_finished.emit()

func get_neighbor_cells(cell: Cell) -> Array[Cell]:
	var pos: Vector2i = _get_cell_pos(cell)
	if pos == Vector2i(-1, -1):
		return [null, null, null, null]
	return [
		cell_map.get(pos + Vector2i(0, -1), null) as Cell, # N
		cell_map.get(pos + Vector2i(1, 0), null) as Cell,  # E
		cell_map.get(pos + Vector2i(0, 1), null) as Cell,  # S
		cell_map.get(pos + Vector2i(-1, 0), null) as Cell, # W
	]

func update_visibility() -> void:
	var cells: Array[Cell] = _get_all_cells()
	visible_cells.clear()
	if !first_placement_done:
		for cell in cells:
			cell.set_state(2) # CellState.VISITED
			visible_cells[cell] = true
	else:
		for cell in cells:
			cell.set_state(0) # CellState.HIDDEN

		for cell in cells:
			if cell.is_visited_by_player():
				visible_cells[cell] = true

		var enemy_cells: Array[Cell] = _get_enemy_cells()
		for enemy_cell in enemy_cells:
			visible_cells[enemy_cell] = true
			var neighbors: Array[Cell] = get_neighbor_cells(enemy_cell)
			for n in neighbors:
				if n != null:
					visible_cells[n] = true

		for key in visible_cells.keys():
			var cell: Cell = key as Cell
			cell.set_state(2) # CellState.VISITED

	_apply_available_cells()

func on_player_unit_placed(cell: Cell) -> void:
	first_placement_done = true
	cell.mark_visited()
	update_visibility()

func on_player_unit_moved(from_cell: Cell, to_cell: Cell) -> void:
	first_placement_done = true
	from_cell.mark_visited()
	to_cell.mark_visited()
	update_visibility()

func on_enemy_updated() -> void:
	update_visibility()

func can_place_on(cell: Cell) -> bool:
	if cell == null:
		return false
	if !first_placement_done:
		return true
	return visible_cells.has(cell)

func set_available_cells(cells: Array[Cell]) -> void:
	clear_available_cells(false)
	available_cells = cells.duplicate()
	_apply_available_cells()

func clear_available_cells(recompute: bool = true) -> void:
	for cell in available_cells:
		cell.set_highlight(false)
	available_cells.clear()
	if recompute:
		update_visibility()

func _apply_available_cells() -> void:
	for cell in available_cells:
		if _cell_has_enemy(cell):
			cell.set_highlight(true, enemy_cell_highlight_color)
		else:
			cell.set_highlight(true)
		cell.set_state(1) # CellState.AVAILABLE

func _index_cells() -> void:
	cell_map.clear()
	if grid == null:
		return
	var children: Array[Node] = grid.get_children()
	for i in range(children.size()):
		var cell: Cell = children[i] as Cell
		if cell == null:
			continue
		var pos: Vector2i = _parse_cell_name(cell.name)
		if pos == Vector2i(-1, -1):
			var columns: int = max(1, grid.columns)
			pos = Vector2i(i % columns, i / columns)
		cell.set_meta("grid_x", pos.x)
		cell.set_meta("grid_y", pos.y)
		cell.board = self
		cell_map[pos] = cell

func _get_all_cells() -> Array[Cell]:
	var cells: Array[Cell] = []
	for cell in cell_map.values():
		cells.append(cell as Cell)
	return cells

func resolve_turn(units: Array = []) -> void:
	var targets: Array = units
	if targets.is_empty():
		targets = _collect_all_units()
	for unit in targets:
		if !is_instance_valid(unit):
			continue
		var u: UnitCard = unit as UnitCard
		if u == null:
			continue
		await u.resolve_turn()

func _collect_all_units() -> Array[UnitCard]:
	var units: Array[UnitCard] = []
	for cell in _get_all_cells():
		var unit: UnitCard = _get_unit_from_cell(cell)
		if unit != null:
			units.append(unit)
	return units

func _get_unit_from_cell(cell: Cell) -> UnitCard:
	if cell == null:
		return null
	return cell.get_unit() as UnitCard

func _get_enemy_cells() -> Array[Cell]:
	var enemies: Array[Cell] = []
	var cells: Array[Cell] = _get_all_cells()
	for cell in cells:
		if _cell_has_enemy(cell):
			enemies.append(cell)
	return enemies

func _cell_has_enemy(cell: Cell) -> bool:
	if cell == null:
		return false
	var unit: UnitCard = _get_unit_from_cell(cell)
	return unit != null and unit.is_enemy_unit()

func _parse_cell_name(name: String) -> Vector2i:
	if name.begins_with("Cell") and name.length() >= 6:
		var x_str: String = name.substr(4, 1)
		var y_str: String = name.substr(5, 1)
		if x_str.is_valid_int() and y_str.is_valid_int():
			# Name format is CellRC (row, col). Convert to (col, row).
			return Vector2i(int(y_str), int(x_str))
	return Vector2i(-1, -1)

func _get_cell_pos(cell: Node) -> Vector2i:
	if cell == null:
		return Vector2i(-1, -1)
	if cell.has_meta("grid_x") and cell.has_meta("grid_y"):
		return Vector2i(int(cell.get_meta("grid_x")), int(cell.get_meta("grid_y")))
	return _parse_cell_name(cell.name)
