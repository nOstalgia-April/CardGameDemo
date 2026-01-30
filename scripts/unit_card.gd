extends Control
class_name UnitCard

signal died(unit: Node, killer: Node, dir: int)

@export_group("Visual")
@export var player_color: Color = Color(0.2, 0.45, 1.0, 0.35)
@export var enemy_color: Color = Color(1.0, 0.25, 0.25, 0.35)
@export var hover_border_color: Color = Color(1, 1, 1, 1)
@export var enemy_border_color: Color = Color(1, 0.2, 0.2, 1)
@export var flipped_border_color: Color = Color(1.0, 0.906, 0.2, 1.0)
@export var border_width: int = 4

@export_group("Combat")
@export var max_attacks_per_turn: int = 1
@export var bump_distance: float = 30.0
@export var bump_duration_forward: float = 0.1
@export var bump_duration_backward: float = 0.15

@export_group("")
var is_enemy: bool = false
var custom_resolver: UnitResolver = null
var death_behavior: String = ""
var death_transform: Dictionary = {}
var effect_id: String = ""

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
var base_n: int = 0
var base_e: int = 0
var base_s: int = 0
var base_w: int = 0

var _hover_active: bool = false
var _enemy_highlight_active: bool = false
var _selecting: bool = false
var _neighbor_cells: Array[Cell] = []
var _dead: bool = false
var attacks_left: int = 0
var unit_id: int = -1
var _bump_tween: Tween = null
var _flip_highlight_active: bool = false
var swap_ready: bool = false
var knockback_on_hit: bool = false
var knockback_on_hurt: bool = false
var death_used: bool = false
var _ui_ready: bool = false
var turn_manager: TurnManager = null

func _ready() -> void:
	_apply_faction_color()
	_setup_border()
	_update_border()
	_reset_attacks()
	_sync_dir_labels()
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	_bind_event_bus()
	_ui_ready = true

func set_is_enemy(flag: bool) -> void:
	is_enemy = flag
	_apply_faction_color()
	_update_border()
	_reset_attacks()

func set_enemy_highlight(active: bool) -> void:
	_enemy_highlight_active = active
	_update_border()

func set_card_data(display_name: String, n: int, e: int, s: int, w: int, enemy: bool = false) -> void:
	is_enemy = enemy
	_apply_faction_color()
	_update_border()
	_reset_attacks()
	base_n = n
	base_e = e
	base_s = s
	base_w = w
	value_n = n
	value_e = e
	value_s = s
	value_w = w
	if _ui_ready:
		_sync_dir_labels()

func set_direction_numbers(numbers: DirectionNumbers, enemy: bool = false) -> void:
	set_card_data("", numbers.get_value("n"), numbers.get_value("e"), numbers.get_value("s"), numbers.get_value("w"), enemy)

func get_direction_numbers() -> DirectionNumbers:
	return DirectionNumbers.new(value_n, value_e, value_s, value_w)

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

func attack(dir: int, advantage: bool = false) -> bool:
	var context: Dictionary = {
		"accepted": false,
	}
	BattleEventBus.emit_signal("unit_attack_requested", self, dir, advantage, context)
	return bool(context.get("accepted", false))

func play_bump_animation(direction: int) -> Tween:
	var bump_vector: Vector2 = Vector2.ZERO
	match direction:
		Dir.N:
			bump_vector = Vector2(0, -bump_distance)
		Dir.E:
			bump_vector = Vector2(bump_distance, 0)
		Dir.S:
			bump_vector = Vector2(0, bump_distance)
		Dir.W:
			bump_vector = Vector2(-bump_distance, 0)
	if bump_vector == Vector2.ZERO:
		return null
	if _bump_tween != null:
		_bump_tween.kill()
	_bump_tween = create_tween()
	var original_position: Vector2 = position
	_bump_tween.set_trans(Tween.TRANS_QUAD)
	_bump_tween.set_ease(Tween.EASE_OUT)
	_bump_tween.tween_property(self, "position", original_position + bump_vector, bump_duration_forward)
	_bump_tween.tween_property(self, "position", original_position, bump_duration_backward)
	_bump_tween.finished.connect(_on_bump_finished)
	return _bump_tween

func _on_bump_finished() -> void:
	_bump_tween = null

func die(killer: Node, dir: int) -> void:
	if _dead:
		return
	_dead = true
	emit_signal("died", self, killer, dir)
	BattleEventBus.emit_signal("unit_died", self, killer, dir, {})

func resolve_turn() -> void:
	if custom_resolver != null:
		await custom_resolver.resolve(self)
	else:
		await get_tree().process_frame

func _reset_attacks() -> void:
	if is_enemy:
		attacks_left = -1
	else:
		attacks_left = max(0, max_attacks_per_turn)

func has_attacks_left() -> bool:
	if is_enemy:
		return true
	return attacks_left > 0

func consume_attack() -> void:
	if is_enemy:
		return
	if attacks_left > 0:
		attacks_left -= 1


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
	if _flip_highlight_active:
		hover_border.visible = true
		hover_border.add_theme_stylebox_override("panel", _make_border_style(flipped_border_color))
	elif _enemy_highlight_active:
		hover_border.visible = true
		hover_border.add_theme_stylebox_override("panel", _make_border_style(enemy_border_color))
	elif _hover_active and !is_enemy:
		hover_border.visible = true
		hover_border.add_theme_stylebox_override("panel", _make_border_style(hover_border_color))
	else:
		hover_border.visible = false

func _bind_event_bus() -> void:
	var cb_attack: Callable = Callable(self, "_on_attack_started")
	BattleEventBus.connect("attack_started", cb_attack)
	var cb_damage: Callable = Callable(self, "_on_damage_applied")
	BattleEventBus.connect("damage_applied", cb_damage)

func _on_attack_started(attacker: Node, _target: Node, dir: int, _context: Dictionary) -> void:
	if attacker == self:
		play_bump_animation(dir) # direct bump (was play_attack_anim)
		if _context.get('advantage'):
			SoundManager.play_sfx('AttackAdvantage')
		else:
			SoundManager.play_sfx('Attack')

func _on_damage_applied(_attacker: Node, target: Node, _dir: int, _value: int, _context: Dictionary) -> void:
	if target == self:
		_update_border()

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
	var label: Label = node.get_node_or_null("Value") as Label
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

func _sync_dir_labels() -> void:
	_apply_dir_value(Dir.N, value_n)
	_apply_dir_value(Dir.E, value_e)
	_apply_dir_value(Dir.S, value_s)
	_apply_dir_value(Dir.W, value_w)

func rotate_numbers(clockwise: bool) -> void:
	var n: int = value_n
	var e: int = value_e
	var s: int = value_s
	var w: int = value_w
	if clockwise:
		_apply_dir_value(Dir.N, w)
		_apply_dir_value(Dir.E, n)
		_apply_dir_value(Dir.S, e)
		_apply_dir_value(Dir.W, s)
	else:
		_apply_dir_value(Dir.N, e)
		_apply_dir_value(Dir.E, s)
		_apply_dir_value(Dir.S, w)
		_apply_dir_value(Dir.W, n)

func heal_full() -> void:
	_apply_dir_value(Dir.N, base_n)
	_apply_dir_value(Dir.E, base_e)
	_apply_dir_value(Dir.S, base_s)
	_apply_dir_value(Dir.W, base_w)

func heal_dir(dir: int) -> void:
	match dir:
		Dir.N:
			_apply_dir_value(Dir.N, base_n)
		Dir.E:
			_apply_dir_value(Dir.E, base_e)
		Dir.S:
			_apply_dir_value(Dir.S, base_s)
		Dir.W:
			_apply_dir_value(Dir.W, base_w)

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
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		if event.pressed:
			flip() # direct flip (was _try_flip)
			accept_event()

func _begin_select() -> void:
	if _selecting:
		return
	_selecting = true
	_hover_active = true
	_neighbor_cells = _get_available_neighbor_cells()
	BattleEventBus.emit_signal("available_cells_requested", _neighbor_cells, {}) # request highlight
	_update_border()

func _end_select() -> void:
	if !_selecting:
		return
	_selecting = false
	var target_cell: Node = _get_target_cell(_neighbor_cells)
	BattleEventBus.emit_signal("clear_available_cells_requested", {}) # request clear
	_neighbor_cells.clear()

	if target_cell != null:
		var target: Cell = target_cell as Cell
		var context: Dictionary = {
			"accepted": false,
		}
		BattleEventBus.emit_signal("unit_action_requested", self, target, context)

	_hover_active = get_global_rect().has_point(get_global_mouse_position()) # direct hover check (was _is_mouse_over)
	_update_border()
	# Visibility now comes from state updates

func _handle_attack(target_cell: Cell) -> void:
	var from_cell: Cell = _get_parent_cell() as Cell
	if from_cell == null:
		return
	var neighbors: Array[Cell] = _get_neighbor_cells()
	var dir: int = neighbors.find(target_cell)
	attack(dir, false)

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
	var context: Dictionary = {
		"neighbors": [],
	}
	BattleEventBus.emit_signal("cell_neighbors_requested", cell, context)
	return context.get("neighbors", [])

func _get_available_neighbor_cells() -> Array[Cell]:
	var neighbors: Array[Cell] = _get_neighbor_cells()
	if is_enemy:
		return neighbors
	var filtered: Array[Cell] = []
	var attacks_left_state: int = attacks_left
	for i in range(neighbors.size()):
		var cell: Cell = neighbors[i]
		if cell == null:
			continue
		if _cell_has_friendly(cell):
			continue
		if _cell_has_enemy(cell) and (get_dir_value(i) <= 0 or attacks_left_state <= 0):
			continue
		filtered.append(cell)
	return filtered

func _cell_has_enemy(cell: Cell) -> bool:
	var unit: UnitCard = cell.get_unit() as UnitCard
	return unit != null and unit.is_enemy

func _cell_has_friendly(cell: Cell) -> bool:
	var unit: UnitCard = cell.get_unit() as UnitCard
	return unit != null and unit.is_enemy == is_enemy

func _get_target_cell(candidates: Array[Cell]) -> Cell:
	var mouse_pos: Vector2 = get_global_mouse_position()
	for cell in candidates:
		var c: Control = cell as Control
		if c != null and c.get_global_rect().has_point(mouse_pos):
			return cell
	return null

func flip(context: Dictionary = {}) -> bool:
	if turn_manager != null and !turn_manager.use_flip():
		return false
	if effect_id != "":
		apply_effect(effect_id, context)
	BattleEventBus.emit_signal("flip_used", self, context)
	_on_flip()
	return true

func apply_effect(effect_id: String, context: Dictionary = {}) -> void:
	if effect_id == "":
		return
	match effect_id:
		"rotate":
			rotate_numbers(true)
			_rotate_adjacent_units(false)
		"swap":
			swap_ready = true
		"knockback":
			knockback_on_hit = true
			knockback_on_hurt = true
		"heal_adjacent":
			_heal_adjacent_edges()
		"heal_self":
			heal_full()
	BattleEventBus.emit_signal("effect_triggered", effect_id, self, context)

func _on_flip() -> void:
	# 占位：翻牌逻辑后续在这里实现
	_flip_highlight_active = true
	_update_border()

func set_flipped(active: bool) -> void:
	_flip_highlight_active = active
	_update_border()

func try_death_transform() -> bool:
	if death_behavior != "transform":
		return false
	if death_used or death_transform.is_empty():
		return false
	death_used = true
	_dead = false
	var n: int = int(death_transform.get("n", value_n))
	var e: int = int(death_transform.get("e", value_e))
	var s: int = int(death_transform.get("s", value_s))
	var w: int = int(death_transform.get("w", value_w))
	base_n = n
	base_e = e
	base_s = s
	base_w = w
	_apply_dir_value(Dir.N, n)
	_apply_dir_value(Dir.E, e)
	_apply_dir_value(Dir.S, s)
	_apply_dir_value(Dir.W, w)
	return true

func _rotate_adjacent_units(clockwise: bool) -> void:
	var cell: Cell = _get_parent_cell() as Cell
	if cell == null:
		return
	var context: Dictionary = {
		"neighbors": [],
	}
	BattleEventBus.emit_signal("cell_neighbors_requested", cell, context)
	var neighbors: Array = context.get("neighbors", [])
	for i in range(neighbors.size()):
		var neighbor_cell: Cell = neighbors[i] as Cell
		if neighbor_cell == null:
			continue
		var unit: UnitCard = neighbor_cell.get_unit() as UnitCard
		if unit == null:
			continue
		unit.rotate_numbers(clockwise)

func _heal_adjacent_edges() -> void:
	var cell: Cell = _get_parent_cell() as Cell
	if cell == null:
		return
	var context: Dictionary = {
		"neighbors": [],
	}
	BattleEventBus.emit_signal("cell_neighbors_requested", cell, context)
	var neighbors: Array = context.get("neighbors", [])
	for i in range(neighbors.size()):
		var neighbor_cell: Cell = neighbors[i] as Cell
		if neighbor_cell == null:
			continue
		var unit: UnitCard = neighbor_cell.get_unit() as UnitCard
		if unit == null:
			continue
		var opp: int = DirUtils.opposite_dir(i)
		unit.heal_dir(opp)
