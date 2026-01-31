extends Control
class_name Board

@onready var grid: GridContainer = $GridContainer
var cell_map: Dictionary = {}
var first_placement_done: bool = false
var visible_cells: Dictionary = {}
var available_cells: Array[Cell] = []
var _resolving_enemy_turn: bool = false

@export_group("Tuning")
@export var enemy_cell_highlight_color: Color = Color(1, 0.2, 0.2, 1)
@export var cleanup_delay: float = 0.0

@export_group("Refs")
@export var turn_manager_path: NodePath
@export_group("")

@onready var turn_manager: TurnManager = get_node_or_null(turn_manager_path) as TurnManager

enum TeamFilter { ANY, ALLY, ENEMY }

func _ready() -> void:
	add_to_group("board")
	_index_cells()
	BattleEventBus.connect("turn_started", _on_turn_started)
	BattleEventBus.connect("place_card_requested", _on_place_card_requested)
	BattleEventBus.connect("unit_died", _on_unit_died_event)
	BattleEventBus.connect("unit_action_requested", _on_unit_action_requested)
	BattleEventBus.connect("unit_attack_requested", _on_unit_attack_requested)
	BattleEventBus.connect("unit_cell_requested", _on_unit_cell_requested)
	BattleEventBus.connect("cell_neighbors_requested", _on_cell_neighbors_requested)
	BattleEventBus.connect("units_requested", _on_units_requested)
	BattleEventBus.connect("available_cells_requested", _on_available_cells_requested)
	BattleEventBus.connect("clear_available_cells_requested", _on_clear_available_cells_requested)
	update_visibility()

func _on_turn_started(_turn_index: int, _context: Dictionary) -> void:
	reset_attacks_for_player()

func _on_place_card_requested(card: Node, cell: Node, context: Dictionary) -> void:
	var placed: bool = place_card_on_cell(card as Card, cell as Cell, context)
	context["accepted"] = placed

func _on_unit_died_event(unit: Node, killer: Node, dir: int, _context: Dictionary) -> void:
	on_unit_died(unit, killer, dir)

func _on_unit_action_requested(unit: Node, target_cell: Node, context: Dictionary) -> void:
	var ok: bool = try_unit_action(unit as UnitCard, target_cell as Cell)
	context["accepted"] = ok

func _on_unit_attack_requested(unit: Node, dir: int, advantage: bool, context: Dictionary) -> void:
	var attacker: UnitCard = unit as UnitCard
	var ok: bool = resolve_attack_dir(attacker, dir, advantage, !attacker.is_enemy)
	context["accepted"] = ok

func _on_unit_cell_requested(unit: Node, context: Dictionary) -> void:
	context["cell"] = get_parent_cell_of_unit(unit as UnitCard)

func _on_cell_neighbors_requested(cell: Node, context: Dictionary) -> void:
	context["neighbors"] = get_neighbor_cells_array(cell as Cell)

func _on_units_requested(filter: Variant, context: Dictionary) -> void:
	context["units"] = find_units(filter)

func _on_available_cells_requested(cells: Array, _context: Dictionary) -> void:
	set_available_cells(cells)

func _on_clear_available_cells_requested(_context: Dictionary) -> void:
	clear_available_cells(true)

func place_card_on_cell(card: Card, cell: Cell, context: Dictionary = {}) -> bool:
	if cell.is_occupied(): # direct occupancy check (was is_cell_empty)
		return false
	if !can_place_on(cell):
		return false
	var effect_id: String = card.card_effect_id
	if turn_manager != null:
		if !turn_manager.can_spend_energy(1):
			return false
		if effect_id == "charge" and !turn_manager.can_use_flip():
			return false
	var display_name: String = card.card_display_name
	var numbers: DirectionNumbers = card.get_direction_numbers()
	var placed: bool = cell.spawn_unit_numbers(display_name, numbers, false)
	if !placed:
		return false
	var unit: UnitCard = cell.get_unit() as UnitCard
	if unit != null:
		unit.effect_id = effect_id
		_bind_unit_refs(unit)
		unit._reset_attacks() # direct reset (was reset_attacks)
		if effect_id == "charge" and turn_manager != null:
			turn_manager.use_flip()
			BattleEventBus.emit_signal("flip_used", unit, context)
	if turn_manager != null:
		turn_manager.spend_energy(1)

	on_player_unit_placed(cell)
	BattleEventBus.emit_signal("unit_placed", unit, cell, context)
	if unit != null and effect_id == "charge":
		_execute_charge_attack(unit, context)
	return true

func place_existing_unit(unit: UnitCard, cell: Cell, context: Dictionary = {}) -> bool:
	var from_cell: Cell = get_parent_cell_of_unit(unit)
	var placed: bool = cell.place_existing_unit(unit)
	if !placed:
		return false
	_bind_unit_refs(unit)
	if from_cell == null:
		if unit.is_enemy:
			update_visibility() # direct refresh (was on_enemy_updated)
		else:
			on_player_unit_placed(cell)
		BattleEventBus.emit_signal("unit_placed", unit, cell, context)
		return true
	if unit.is_enemy:
		update_visibility() # direct refresh (was on_enemy_updated)
	else:
		on_player_unit_moved(from_cell, cell)
	BattleEventBus.emit_signal("unit_moved", unit, from_cell, cell, context)
	return true

func try_unit_action(unit: UnitCard, target_cell: Cell, consume_energy: bool = true) -> bool:
	var target_unit: UnitCard = target_cell.get_unit() as UnitCard
	if unit.swap_ready and target_unit != null:
		return _swap_units(unit, target_unit, consume_energy)
	if target_unit != null and target_unit.is_enemy != unit.is_enemy:
		return resolve_attack_on_cell(unit, target_cell, false, consume_energy)
	if target_unit != null:
		return false
	return move_unit(unit, target_cell, consume_energy)

func move_unit(unit: UnitCard, target_cell: Cell, consume_energy: bool = true) -> bool:
	if target_cell.is_occupied():
		return false
	var from_cell: Cell = get_parent_cell_of_unit(unit)
	if from_cell == target_cell:
		return false
	if consume_energy and !unit.is_enemy:
		if turn_manager != null and !turn_manager.can_spend_energy(1):
			SoundManager.play_sfx("HandviewNoCostError")
			return false
	var moved: bool = target_cell.place_existing_unit(unit)
	if !moved:
		return false
	_bind_unit_refs(unit)
	if consume_energy and !unit.is_enemy and turn_manager != null:
		turn_manager.spend_energy(1)
	if unit.is_enemy:
		update_visibility() # direct refresh (was on_enemy_updated)
	else:
		on_player_unit_moved(from_cell, target_cell)
	BattleEventBus.emit_signal("unit_moved", unit, from_cell, target_cell, {})
	return true

func resolve_attack_on_cell(attacker: UnitCard, target_cell: Cell, advantage: bool = false, consume_energy: bool = true) -> bool:
	var attacker_cell: Cell = get_parent_cell_of_unit(attacker)
	var dir: int = _get_dir_between_cells(attacker_cell, target_cell)
	if dir < 0:
		return false
	return resolve_attack_dir(attacker, dir, advantage, consume_energy)

func resolve_attack_dir(attacker: UnitCard, dir: int, advantage: bool = false, consume_energy: bool = true) -> bool:
	var attacker_cell: Cell = get_parent_cell_of_unit(attacker)
	var target_cell: Cell = get_neighbor_cells(attacker_cell).get(dir, null) as Cell # direct neighbor lookup (was get_neighbor_cell_by_dir)
	var target: UnitCard = target_cell.get_unit() as UnitCard
	var atk_value: int = attacker.get_dir_value(dir)
	if atk_value <= 0:
		return false
	if consume_energy and !attacker.is_enemy:
		if attacker.attacks_left <= 0:
			return false
		if turn_manager != null and !turn_manager.can_spend_energy(1):
			return false
	var def_dir: int = DirUtils.opposite_dir(dir)
	var def_value: int = target.get_dir_value(def_dir)
	var event_context: Dictionary = {"advantage": advantage}
	BattleEventBus.emit_signal("attack_started", attacker, target, dir, event_context)
	BattleEventBus.emit_signal("screen_shake_requested", 0.0, 0.0, event_context)
	target.take_damage(def_dir, attacker, atk_value)
	BattleEventBus.emit_signal("damage_applied", attacker, target, dir, atk_value, event_context)
	if !advantage:
		attacker.take_damage(dir, target, def_value)
		BattleEventBus.emit_signal("damage_applied", target, attacker, DirUtils.opposite_dir(dir), def_value, event_context)
	if consume_energy and !attacker.is_enemy:
		if turn_manager != null:
			turn_manager.spend_energy(1)
		attacker.consume_attack()
	return true

func on_unit_died(unit: Node, killer: Node, dir: int) -> void:
	if !is_instance_valid(unit):
		return
	var u: UnitCard = unit as UnitCard
	if u != null and u.try_death_transform():
		update_visibility()
		return
	if cleanup_delay > 0.0:
		var timer: SceneTreeTimer = get_tree().create_timer(cleanup_delay)
		await timer.timeout
	if is_instance_valid(unit):
		var parent_cell: Cell = get_parent_cell_of_unit(u)
		if parent_cell != null:
			parent_cell.remove_unit()
		unit.queue_free()
	update_visibility()

func reset_attacks_for_player() -> void:
	for cell in _get_all_cells():
		var unit: UnitCard = cell.get_unit() as UnitCard
		if unit == null:
			continue
		if unit.is_enemy:
			continue
		unit._reset_attacks() # direct reset (was reset_attacks)

func resolve_enemy_turn() -> void:
	if _resolving_enemy_turn:
		return
	_resolving_enemy_turn = true
	await get_tree().create_timer(1.5).timeout
	var enemies: Array[UnitCard] = find_units("enemy")
	for unit in enemies:
		if unit == null or !is_instance_valid(unit):
			continue
		await unit.resolve_turn()
	await get_tree().create_timer(1.0).timeout
	_resolving_enemy_turn = false

func get_neighbor_cells(cell: Cell) -> Dictionary:
	var pos: Vector2i = get_cell_pos(cell)
	if pos == Vector2i(-1, -1):
		return {0: null, 1: null, 2: null, 3: null}
	return {
		0: cell_map.get(pos + Vector2i(0, -1), null) as Cell,
		1: cell_map.get(pos + Vector2i(1, 0), null) as Cell,
		2: cell_map.get(pos + Vector2i(0, 1), null) as Cell,
		3: cell_map.get(pos + Vector2i(-1, 0), null) as Cell,
	}

func get_neighbor_cells_array(cell: Cell) -> Array[Cell]:
	var neighbors: Dictionary = get_neighbor_cells(cell)
	return [
		neighbors.get(0, null) as Cell,
		neighbors.get(1, null) as Cell,
		neighbors.get(2, null) as Cell,
		neighbors.get(3, null) as Cell,
	]

func highlight_cells(cells: Array, color: Color = Color(1, 1, 1, 0.9)) -> void:
	clear_available_cells(true) # direct clear (was clear_highlight)
	var cell_list: Array[Cell] = []
	for entry in cells:
		var cell: Cell = entry as Cell
		if cell == null:
			continue
		cell_list.append(cell)
	available_cells = cell_list
	_apply_available_cells(color)

func update_visibility() -> void:
	var cells: Array[Cell] = _get_all_cells()
	var computed: Dictionary = _compute_visible_cells_local(cells)
	visible_cells = computed.duplicate()
	if !first_placement_done:
		for cell in cells:
			cell.set_state(Cell.CellState.VISITED)
			_emit_visibility(cell, Cell.CellState.VISITED)
	else:
		for cell in cells:
			cell.set_state(Cell.CellState.HIDDEN)
			_emit_visibility(cell, Cell.CellState.HIDDEN)
		for key in visible_cells.keys():
			var cell: Cell = key as Cell
			if cell == null:
				continue
			cell.set_state(Cell.CellState.VISITED)
			_emit_visibility(cell, Cell.CellState.VISITED)
	_apply_available_cells()

func get_distance(cell_a: Cell, cell_b: Cell) -> int:
	var pos_a: Vector2i = get_cell_pos(cell_a)
	var pos_b: Vector2i = get_cell_pos(cell_b)
	return abs(pos_a.x - pos_b.x) + abs(pos_a.y - pos_b.y)

func find_units(filter: Variant = null) -> Array[UnitCard]:
	var results: Array[UnitCard] = []
	for cell in _get_all_cells():
		var unit: UnitCard = cell.get_unit() as UnitCard
		if unit == null:
			continue
		if filter is String:
			var tag: String = str(filter).to_lower()
			if tag == "enemy" and !unit.is_enemy:
				continue
			if (tag == "ally" or tag == "player") and unit.is_enemy:
				continue
		elif filter is Callable:
			var cb: Callable = filter
			if !cb.call(unit):
				continue
		results.append(unit)
	return results

func get_manhattan_distance(unit_a: UnitCard, unit_b: UnitCard) -> int:
	var cell_a: Cell = get_parent_cell_of_unit(unit_a)
	var cell_b: Cell = get_parent_cell_of_unit(unit_b)
	return get_distance(cell_a, cell_b)

func get_nearest_unit(from_unit: UnitCard, team: TeamFilter = TeamFilter.ANY) -> UnitCard:
	var origin_cell: Cell = get_parent_cell_of_unit(from_unit)
	var origin_pos: Vector2i = get_cell_pos(origin_cell)
	var best_unit: UnitCard = null
	var best_dist: int = 1_000_000
	for cell in _get_all_cells():
		var unit: UnitCard = _get_unit_from_cell(cell)
		if unit == null or unit == from_unit:
			continue
		if team == TeamFilter.ALLY and unit.is_enemy != from_unit.is_enemy:
			continue
		if team == TeamFilter.ENEMY and unit.is_enemy == from_unit.is_enemy:
			continue
		var pos: Vector2i = get_cell_pos(cell)
		var dist: int = abs(pos.x - origin_pos.x) + abs(pos.y - origin_pos.y)
		if dist < best_dist:
			best_dist = dist
			best_unit = unit
	return best_unit

func on_player_unit_placed(cell: Cell) -> void:
	first_placement_done = true
	cell.mark_visited()
	update_visibility()

func on_player_unit_moved(from_cell: Cell, to_cell: Cell) -> void:
	first_placement_done = true
	from_cell.mark_visited()
	to_cell.mark_visited()
	update_visibility()

func can_place_on(cell: Cell) -> bool:
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

func _apply_available_cells(color: Color = Color(1, 1, 1, 0.9)) -> void:
	for cell in available_cells:
		if _cell_has_enemy(cell):
			cell.set_highlight(true, enemy_cell_highlight_color)
		else:
			cell.set_highlight(true, color)
		cell.set_state(Cell.CellState.AVAILABLE)
		_emit_visibility(cell, Cell.CellState.AVAILABLE)

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
		#cell.set_base_texture(((pos.x + pos.y) % 2) == 0)
		cell_map[pos] = cell
	for cell in _get_all_cells():
		var unit: UnitCard = cell.get_unit() as UnitCard
		if unit != null:
			_bind_unit_refs(unit)

func _get_all_cells() -> Array[Cell]:
	var cells: Array[Cell] = []
	for cell in cell_map.values():
		cells.append(cell as Cell)
	return cells

func _get_unit_from_cell(cell: Cell) -> UnitCard:
	return cell.get_unit() as UnitCard

func _get_enemy_cells() -> Array[Cell]:
	var enemies: Array[Cell] = []
	for cell in _get_all_cells():
		if _cell_has_enemy(cell):
			enemies.append(cell)
	return enemies

func _cell_has_enemy(cell: Cell) -> bool:
	var unit: UnitCard = _get_unit_from_cell(cell)
	return unit != null and unit.is_enemy

func _find_parent_cell(node: Node) -> Cell:
	var current: Node = node
	while current != null:
		if current.is_in_group("cells"):
			return current as Cell
		current = current.get_parent()
	return null

func get_parent_cell_of_unit(unit: UnitCard) -> Cell:
	return _find_parent_cell(unit) as Cell

func _parse_cell_name(name: String) -> Vector2i:
	if name.begins_with("Cell") and name.length() >= 6:
		var x_str: String = name.substr(4, 1)
		var y_str: String = name.substr(5, 1)
		if x_str.is_valid_int() and y_str.is_valid_int():
			# Name format is CellRC (row, col). Convert to (col, row).
			return Vector2i(int(y_str), int(x_str))
	return Vector2i(-1, -1)

func get_cell_pos(cell: Cell) -> Vector2i:
	if cell.has_meta("grid_x") and cell.has_meta("grid_y"):
		return Vector2i(int(cell.get_meta("grid_x")), int(cell.get_meta("grid_y")))
	return _parse_cell_name(cell.name)

func get_cell_at(pos: Vector2i) -> Cell:
	return cell_map.get(pos, null) as Cell

func _get_dir_between_cells(from_cell: Cell, to_cell: Cell) -> int:
	var from_pos: Vector2i = get_cell_pos(from_cell)
	var to_pos: Vector2i = get_cell_pos(to_cell)
	return DirUtils.vec_to_dir(to_pos - from_pos)

func _compute_visible_cells_local(cells: Array[Cell]) -> Dictionary:
	var computed: Dictionary = {}
	if !first_placement_done:
		for cell in cells:
			computed[cell] = true
		return computed
	for cell in cells:
		if cell.is_visited_by_player():
			computed[cell] = true
	var enemy_cells: Array[Cell] = _get_enemy_cells()
	for enemy_cell in enemy_cells:
		computed[enemy_cell] = true
		var neighbors: Array[Cell] = get_neighbor_cells_array(enemy_cell)
		for n in neighbors:
			if n != null:
				computed[n] = true
	return computed

func _emit_visibility(cell: Cell, state: int) -> void:
	BattleEventBus.emit_signal("cell_visibility_changed", cell, state)

func _bind_unit_refs(unit: UnitCard) -> void:
	unit.turn_manager = turn_manager # direct set (was set_turn_manager)

func _swap_units(unit: UnitCard, target: UnitCard, consume_energy: bool) -> bool:
	var from_cell: Cell = get_parent_cell_of_unit(unit)
	var to_cell: Cell = get_parent_cell_of_unit(target)
	if consume_energy and !unit.is_enemy:
		if turn_manager != null and !turn_manager.can_spend_energy(1):
			return false
	var unit_a: UnitCard = from_cell.remove_unit()
	var unit_b: UnitCard = to_cell.remove_unit()
	if unit_a == null or unit_b == null:
		return false
	from_cell.place_existing_unit(unit_b, false)
	to_cell.place_existing_unit(unit_a, false)
	_bind_unit_refs(unit_a)
	_bind_unit_refs(unit_b)
	unit.swap_ready = false
	if consume_energy and !unit.is_enemy and turn_manager != null:
		turn_manager.spend_energy(1)
	if !unit.is_enemy:
		on_player_unit_moved(from_cell, to_cell)
	else:
		update_visibility() # direct refresh (was on_enemy_updated)
	if !target.is_enemy:
		on_player_unit_moved(to_cell, from_cell)
	else:
		update_visibility() # direct refresh (was on_enemy_updated)
	BattleEventBus.emit_signal("unit_moved", unit_a, from_cell, to_cell, {"swap": true})
	BattleEventBus.emit_signal("unit_moved", unit_b, to_cell, from_cell, {"swap": true})
	return true

func _execute_charge_attack(unit: UnitCard, context: Dictionary) -> void:
	var attacker_cell: Cell = get_parent_cell_of_unit(unit)
	var neighbors: Array[Cell] = get_neighbor_cells_array(attacker_cell)
	for dir in range(4):
		if dir < 0 or dir >= neighbors.size():
			continue
		var target_cell: Cell = neighbors[dir]
		if target_cell == null:
			continue
		if target_cell.get_unit() == null:
			continue
		resolve_attack_dir(unit, dir, true, false)
	BattleEventBus.emit_signal("effect_triggered", "charge", unit, context)
