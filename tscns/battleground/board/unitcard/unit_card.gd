extends Control
class_name UnitCard

signal died(unit: Node, killer: Node, dir: int)
signal values_changed(unit: Node)

const FlipEffectRegistry = preload("res://scripts/effects/flip_effect_registry.gd")
const FlipTriggerRegistry = preload("res://scripts/triggers/flip_trigger_registry.gd")

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
var death_transform: EnemyData = null
var _effect_id: String = ""
var _flip_trigger_id: String = ""
var effect_id: String:
	get:
		return _effect_id
	set(value):
		_effect_id = value
var flip_trigger_id: String:
	get:
		return _flip_trigger_id
	set(value):
		_flip_trigger_id = value
		_apply_flip_trigger()
var display_name: String = ""
var description: String = ""

@onready var card_bg: Panel = $CardBg
@onready var art: TextureRect = $CardBg/Art
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
var _bump_origin: Vector2 = Vector2.ZERO
var _bump_origin_set: bool = false
var _flip_highlight_active: bool = false
var swap_ready: bool = false
var death_used: bool = false
var _ui_ready: bool = false
var turn_manager: TurnManager = null
var _select_sfx_requester: String = ""
var _active_effects: Dictionary = {}
var _flipped: bool = false
var _flip_trigger: FlipTrigger = FlipTriggerRegistry.create("none")
var _card_art: Texture2D = null
var _card_art_flipped: Texture2D = null
var _portrait: Texture2D = null
var _portrait_flipped: Texture2D = null

func _ready() -> void:
	_apply_faction_color()
	_setup_border()
	_update_border()
	_reset_attacks()
	_sync_dir_labels()
	_select_sfx_requester = "UnitCardSelect_%s" % str(get_instance_id())
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	_bind_event_bus()
	_apply_flip_trigger()
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
	self.display_name = display_name
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

func apply_enemy_data(data: EnemyData, enemy: bool = true) -> void:
	if data == null:
		return
	var display_name: String = data.display_name if data.display_name != "" else data.enemy_key
	set_card_data(display_name, data.n, data.e, data.s, data.w, enemy)
	description = data.desc
	# Only update art if the new data actually has art defined.
	# This allows "data-only" updates (like phase 2 stats) to inherit the previous form's art (flipped or not).
	if data.card_art != null or data.card_art_flipped != null:
		set_art(data.card_art, data.card_art_flipped)
	
	if data.portrait != null or data.portrait_flipped != null:
		_portrait = data.portrait
		_portrait_flipped = data.portrait_flipped
	
	effect_id = data.flip_effect_id
	flip_trigger_id = data.flip_trigger_id
	death_transform = data.death_transform
	
	if data.resolver_script != null:
		if data.resolver_script is Script:
			custom_resolver = data.resolver_script.new()
		elif data.resolver_script is UnitResolver:
			custom_resolver = data.resolver_script.duplicate()
	else:
		custom_resolver = null

func set_art(texture: Texture2D, flipped: Texture2D = null) -> void:
	_card_art = texture
	_card_art_flipped = flipped
	
	if !is_instance_valid(art):
		return
		
	if _flipped and _card_art_flipped != null:
		art.texture = _card_art_flipped
	else:
		if _card_art != null:
			art.texture = _card_art

func get_direction_numbers() -> DirectionNumbers:
	return DirectionNumbers.new(value_n, value_e, value_s, value_w)

func take_damage(dir: int, attacker: Node, value: int) -> Dictionary:
	var def_before: int = get_dir_value(dir)
	if def_before <= 0 and value > 0:
		if _flip_trigger.on_death({"attacker": attacker, "dir": dir}):
			return {
				"def_before": def_before,
				"def_after": get_dir_value(dir),
				"damage": value,
				"attacker": attacker,
				"destroyed": false,
				"transformed": true,
			}
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
	_ensure_centered_in_slot()
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
		if _bump_origin_set:
			position = _bump_origin
	_bump_origin = position
	_bump_origin_set = true
	_bump_tween = create_tween()
	var original_position: Vector2 = _bump_origin
	_bump_tween.set_trans(Tween.TRANS_QUAD)
	_bump_tween.set_ease(Tween.EASE_OUT)
	_bump_tween.tween_property(self, "position", original_position + bump_vector, bump_duration_forward)
	_bump_tween.tween_property(self, "position", original_position, bump_duration_backward)
	_bump_tween.finished.connect(_on_bump_finished)
	return _bump_tween

func _on_bump_finished() -> void:
	if _bump_origin_set:
		position = _bump_origin
	_bump_tween = null

func _ensure_centered_in_slot() -> void:
	var slot: Control = get_parent() as Control
	if slot == null:
		return
	var slot_size: Vector2 = slot.size
	if slot_size.x <= 0.0 or slot_size.y <= 0.0:
		return
	var base_size: Vector2 = custom_minimum_size
	if base_size.x <= 0.0 or base_size.y <= 0.0:
		base_size = size
	if base_size.x <= 0.0 or base_size.y <= 0.0:
		return
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	size = base_size
	scale = Vector2.ONE
	position = (slot_size - base_size) * 0.5

func die(killer: Node, dir: int) -> void:
	if _dead:
		return
	_dead = true
	_clear_trigger()
	_clear_effects()
	SoundManager.request_loop_sfx("UnitSelecting", _select_sfx_requester, false)
	SoundManager.play_sfx("UnitOnDeath")
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
	#if card_bg.has_theme_stylebox_override("panel"):
		#card_bg.remove_theme_stylebox_override("panel")

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
	BattleEventBus.connect("attack_started", _on_attack_started)
	BattleEventBus.connect("damage_applied", _on_damage_applied)
	BattleEventBus.connect("unit_placed", _on_unit_placed)

func _on_attack_started(attacker: Node, _target: Node, dir: int, _context: Dictionary) -> void:
	if attacker == self:
		var tween = play_bump_animation(dir) # direct bump (was play_attack_anim)
		if _context.get('advantage'):
			SoundManager.play_sfx('AttackAdvantage')
		else:
			SoundManager.play_sfx('Attack')
		await tween.finished
		BattleEventBus.emit_signal("attack_anim_finished", self)

func _on_damage_applied(_attacker: Node, target: Node, _dir: int, _value: int, _context: Dictionary) -> void:
	if target == self:
		_update_border()

func _on_unit_placed(unit: Node, _cell: Node, _context: Dictionary) -> void:
	if unit == self:
		SoundManager.play_sfx("UnitOnPlaced")

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
	var prev_value: int = 0
	match dir:
		Dir.N:
			prev_value = value_n
			value_n = value
			if dir_n != null:
				dir_n.visible = value_n > 0
			_set_dir_value(dir_n, value)
		Dir.E:
			prev_value = value_e
			value_e = value
			if dir_e != null:
				dir_e.visible = value_e > 0
			_set_dir_value(dir_e, value)
		Dir.S:
			prev_value = value_s
			value_s = value
			if dir_s != null:
				dir_s.visible = value_s > 0
			_set_dir_value(dir_s, value)
		Dir.W:
			prev_value = value_w
			value_w = value
			if dir_w != null:
				dir_w.visible = value_w > 0
			_set_dir_value(dir_w, value)
	if prev_value > 0 and value <= 0:
		SoundManager.play_sfx("UnitBreakShield")
	
	emit_signal("values_changed", self)

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
	# Store original positions
	var pos_n: Vector2 = dir_n.position
	var pos_e: Vector2 = dir_e.position
	var pos_s: Vector2 = dir_s.position
	var pos_w: Vector2 = dir_w.position
	
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN_OUT)
	var duration: float = 0.3
	
	if clockwise:
		# N -> E, E -> S, S -> W, W -> N
		tween.tween_property(dir_n, "position", pos_e, duration)
		tween.tween_property(dir_e, "position", pos_s, duration)
		tween.tween_property(dir_s, "position", pos_w, duration)
		tween.tween_property(dir_w, "position", pos_n, duration)
	else:
		# N -> W, W -> S, S -> E, E -> N
		tween.tween_property(dir_n, "position", pos_w, duration)
		tween.tween_property(dir_w, "position", pos_s, duration)
		tween.tween_property(dir_s, "position", pos_e, duration)
		tween.tween_property(dir_e, "position", pos_n, duration)
		
	await tween.finished
	
	# Apply logic changes
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
		
	# Reset positions immediately
	dir_n.position = pos_n
	dir_e.position = pos_e
	dir_s.position = pos_s
	dir_w.position = pos_w

func increase_stats(amount: int) -> void:
	_apply_dir_value(Dir.N, value_n + amount)
	_apply_dir_value(Dir.E, value_e + amount)
	_apply_dir_value(Dir.S, value_s + amount)
	_apply_dir_value(Dir.W, value_w + amount)
	SoundManager.play_sfx("UnitOnPlaced") # Or a buff sound

func move_dir(dir: int) -> bool:
	var neighbors: Array[Cell] = _get_neighbor_cells()
	if dir < 0 or dir >= neighbors.size():
		return false
		
	var target_cell: Cell = neighbors[dir]
	if target_cell == null:
		return false
		
	var context: Dictionary = {
		"accepted": false,
	}
	BattleEventBus.emit_signal("unit_action_requested", self, target_cell, context)
	return bool(context.get("accepted", false))

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
	_hover_active = true
	_update_border()
	var context := {
		"global_rect": get_global_rect(),
		"name": display_name,
		"desc": description,
	}
	BattleEventBus.emit_signal("unit_hover_started", context)

func _on_mouse_exited() -> void:
	if _selecting:
		return
	_hover_active = false
	_update_border()
	BattleEventBus.emit_signal("unit_hover_ended")

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
	SoundManager.request_loop_sfx("UnitSelecting", _select_sfx_requester, true)
	_hover_active = true
	_neighbor_cells = _get_available_neighbor_cells()
	BattleEventBus.emit_signal("available_cells_requested", _neighbor_cells, {}) # request highlight
	_update_border()

func _end_select() -> void:
	if !_selecting:
		return
	_selecting = false
	SoundManager.request_loop_sfx("UnitSelecting", _select_sfx_requester, false)
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
	# 切换翻转状态
	_flipped = !_flipped
	
	if effect_id != "":
		await FlipEffectRegistry.apply(effect_id, self, context)
		BattleEventBus.emit_signal("effect_triggered", effect_id, self, context)
	SoundManager.play_sfx('UnitOnFlip')
	BattleEventBus.emit_signal("flip_used", self, context)
	_on_flip()
	_update_portrait_on_flip()
	return true

func _on_flip() -> void:
	_flip_highlight_active = _flipped
	if _flipped:
		if _card_art_flipped != null:
			art.texture = _card_art_flipped
	else:
		if _card_art != null:
			art.texture = _card_art
	_update_border()

func _update_portrait_on_flip() -> void:
	print("[UnitCard] _update_portrait_on_flip: _flipped=", _flipped, " _portrait=", _portrait, " _portrait_flipped=", _portrait_flipped)
	var target_texture: Texture2D = null
	
	if _flipped:
		if _portrait_flipped != null:
			target_texture = _portrait_flipped
		elif _portrait != null:
			# Fallback: 如果没有翻转立绘，使用正面立绘
			target_texture = _portrait
	else:
		if _portrait != null:
			target_texture = _portrait
			
	if target_texture != null:
		print("[UnitCard] Emitting unit_portrait_changed with ", target_texture)
		BattleEventBus.emit_signal("unit_portrait_changed", self, target_texture)

func set_flipped(active: bool) -> void:
	_flip_highlight_active = active
	_update_border()

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

func heal_adjacent_units() -> void:
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
		unit.heal_full()

func _register_effect(effect_id: String, effect: FlipEffect) -> void:
	if _active_effects.has(effect_id):
		var existing: FlipEffect = _active_effects.get(effect_id, null)
		if existing != null:
			existing.cleanup()
	_active_effects[effect_id] = effect

func set_flip_trigger_id(trigger_id: String) -> void:
	flip_trigger_id = trigger_id

func on_placed(context: Dictionary = {}) -> void:
	await _flip_trigger.on_placed(context)

func _apply_flip_trigger() -> void:
	_flip_trigger.cleanup()
	_flip_trigger = FlipTriggerRegistry.create(flip_trigger_id)
	_flip_trigger.bind(self)

func _clear_trigger() -> void:
	_flip_trigger.cleanup()
	_flip_trigger = FlipTriggerRegistry.create("none")
	_flip_trigger.bind(self)

func _clear_effects() -> void:
	for key in _active_effects.keys():
		var effect: FlipEffect = _active_effects[key]
		if effect != null:
			effect.cleanup()
	_active_effects.clear()
