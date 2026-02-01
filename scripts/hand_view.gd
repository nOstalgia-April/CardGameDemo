extends Control
class_name HandView

@export_group("Setup")
@export var card_scene: PackedScene
@export var initial_card_count: int = 3
@export var hand_scale: float = 1.0
@export var hand_z_index: int = 20

@export_group("Layout")
@export var hand_width: float = 900.0
@export var default_spacing: float = 180.0
@export var fan_angle_deg: float = 40.0
@export var max_card_angle_deg: float = 5.0
@export var fan_stop_cards: int = 8
@export var curve_height: float = 90.0
@export var bottom_padding: float = 16.0

@export_group("Hover")
@export var hover_scale: float = 1.7
@export var hover_spread: float = 24.0
@export var hover_rotation_factor: float = 0.6

@export_group("Drag")
@export var drag_out_size: Vector2 = Vector2(140, 180)

@export_group("Motion")
@export var follow_speed: float = 12.0
@export_group("")

@onready var hand_root: Control = self
@onready var hand_area: Control = $HandArea
@onready var card_container: Control = $CardContainer

var cards: Array[Control] = []
var hovered_card: Control = null
var dragging_card: Control = null
var _dragging_inside_hand: bool = false
var _current_energy: int = 0
var _base_hand_scale: Vector2 = Vector2.ONE

func _ready() -> void:
	_sanitize_anchors()
	z_index = hand_z_index
	if is_instance_valid(hand_root):
		_base_hand_scale = hand_root.scale
	_apply_hand_scale()
	BattleEventBus.resource_changed.connect(_on_resource_changed)
	if card_scene == null:
		card_scene = preload("res://tscns/card.tscn")
	for i in range(initial_card_count):
		add_card()

func _sanitize_anchors() -> void:
	if anchor_left >= 0.0 and anchor_left <= 1.0 \
		and anchor_right >= 0.0 and anchor_right <= 1.0 \
		and anchor_top >= 0.0 and anchor_top <= 1.0 \
		and anchor_bottom >= 0.0 and anchor_bottom <= 1.0:
		return
	var parent_control: Control = get_parent_control()
	if parent_control == null:
		return
	var rect := get_global_rect()
	var parent_rect := parent_control.get_global_rect()
	var local_pos := rect.position - parent_rect.position
	var local_size := rect.size
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	offset_left = local_pos.x
	offset_top = local_pos.y
	offset_right = local_pos.x + local_size.x
	offset_bottom = local_pos.y + local_size.y

func add_card() -> Card:
	var card: Card = card_scene.instantiate() as Card
	card_container.add_child(card)
	_setup_card(card)
	cards.append(card)
	_refresh_z()
	return card

func remove_card(card: Control) -> void:
	var index: int = cards.find(card)
	if index != -1:
		cards.remove_at(index)
	if hovered_card == card:
		hovered_card = null
	if is_instance_valid(card):
		card.queue_free()
	_refresh_z()

func clear_cards() -> void:
	hovered_card = null
	for card in cards:
		if is_instance_valid(card):
			card.queue_free()
	cards.clear()

func _setup_card(card: Card) -> void:
	card.set_anchors_preset(Control.PRESET_TOP_LEFT)
	card.z_as_relative = true
	var btn: Button = card.get_node_or_null("Button") as Button
	if btn != null:
		btn.mouse_entered.connect(_on_card_hover.bind(card))
		btn.mouse_exited.connect(_on_card_unhover.bind(card))

func _on_card_hover(card: Control) -> void:
	var c: Card = card as Card
	hovered_card = c
	c.set_hover_visuals(true)
	_refresh_z()

func _on_card_unhover(card: Control) -> void:
	var c: Card = card as Card
	if dragging_card == c:
		return
	if c != null and c.cardCurrentState == Card.cardState.dragging:
		return
	if hovered_card == c:
		hovered_card = null
	c.set_hover_visuals(false)
	_refresh_z()

func _process(delta: float) -> void:
	if hovered_card != null and !is_instance_valid(hovered_card):
		hovered_card = null
	if dragging_card != null and !is_instance_valid(dragging_card):
		dragging_card = null
	_update_drag_hover_state()
	_update_layout(delta)

func _update_layout(delta: float) -> void:
	if cards.is_empty():
		return

	var count := cards.size()
	var g := hand_area.get_global_rect()
	var area_pos: Vector2 = card_container.get_global_transform().affine_inverse() * g.position
	var area_size := g.size
	if area_size.x <= 0.0 or area_size.y <= 0.0:
		area_size = size
		area_pos = Vector2.ZERO
		if area_size.x <= 0.0 or area_size.y <= 0.0:
			area_size = custom_minimum_size

	var max_width: float = min(hand_width, area_size.x)
	var spacing := 0.0
	if count > 1:
		spacing = min(default_spacing, max_width / float(count - 1))
	var total_width := spacing * float(count - 1)

	var left_x := area_pos.x + (area_size.x - max_width) * 0.5
	var center_x := left_x + max_width * 0.5
	var base_y := area_pos.y + area_size.y - bottom_padding

	var angle_span := fan_angle_deg
	if fan_stop_cards > 1:
		var t_span: float = min(1.0, float(count - 1) / float(fan_stop_cards - 1))
		angle_span = fan_angle_deg * t_span
	var span_factor: float = sin(deg_to_rad(angle_span * 0.5))
	var effective_curve_height: float = curve_height * span_factor

	var hovered_index := -1
	var active_hover: Control = dragging_card if dragging_card != null and _dragging_inside_hand else hovered_card
	if active_hover != null:
		hovered_index = cards.find(active_hover)
	
	for i in range(count):
		var card := cards[i]
		if !is_instance_valid(card):
			continue
		if card == dragging_card and !_dragging_inside_hand:
			var base_size: Vector2 = card.custom_minimum_size
			if base_size.x <= 0.0 or base_size.y <= 0.0:
				base_size = card.size
			if base_size.x <= 0.0 or base_size.y <= 0.0:
				base_size = Vector2.ONE
			var target_scale := Vector2(
				drag_out_size.x / base_size.x,
				drag_out_size.y / base_size.y
			)
			var t_drag := 1.0 - pow(0.001, delta * follow_speed)
			card.scale = card.scale.lerp(target_scale, t_drag)
			card.z_index = count + 20
			continue

		var t: float = 0.0
		if count > 1:
			t = float(i) / float(count - 1)

		var angle: float = lerp(-angle_span * 0.5, angle_span * 0.5, t)
		var rot_deg: float = clamp(angle, -max_card_angle_deg, max_card_angle_deg)
		var rot := deg_to_rad(rot_deg)

		var curve_t := (t * 2.0) - 1.0
		var x := center_x - total_width * 0.5 + spacing * float(i)
		var y := base_y - effective_curve_height * (1.0 - curve_t * curve_t)

		var is_hovered: bool = hovered_index >= 0 and i == hovered_index
		var target_pos := Vector2(x, y) - card.pivot_offset
		var target_scale := Vector2.ONE
		var target_rot := rot
		var target_z := i

		if hovered_card != null and hovered_index >= 0:
			if is_hovered:
				if hover_scale != 1.0:
					target_scale = Vector2.ONE * hover_scale
				target_rot = 0.0
				target_z = count + 10
			else:
				var dir: float = sign(float(i - hovered_index))
				target_pos += Vector2(dir * hover_spread, 0)
				target_rot *= hover_rotation_factor

		if is_hovered:
			_apply_direct(card, target_pos, target_rot, target_scale, target_z)
		else:
			_apply_tween(card, target_pos, target_rot, target_scale, target_z, delta)

func _apply_tween(card: Control, target_pos: Vector2, target_rot: float, target_scale: Vector2, target_z: int, delta: float) -> void:
	var t := 1.0 - pow(0.001, delta * follow_speed)
	card.position = card.position.lerp(target_pos, t)
	card.rotation = lerp_angle(card.rotation, target_rot, t)
	card.scale = card.scale.lerp(target_scale, t)
	card.z_index = target_z

func _apply_direct(card: Control, target_pos: Vector2, target_rot: float, target_scale: Vector2, target_z: int) -> void:
	card.position = target_pos
	card.rotation = target_rot
	card.scale = target_scale
	card.z_index = target_z

func _refresh_z() -> void:
	for i in range(cards.size()):
		var card := cards[i]
		if is_instance_valid(card):
			card.z_index = i

func begin_drag(card: Card) -> void:
	dragging_card = card
	hovered_card = card
	card.set_hover_visuals(true)
	_refresh_z()

func end_drag(card: Card, allow_hover: bool = true) -> void:
	if dragging_card == card:
		dragging_card = null
	if hovered_card == card:
		hovered_card = null
	if is_instance_valid(card):
		card.set_hover_visuals(false)
	_dragging_inside_hand = false
	if allow_hover and _is_mouse_over_card(card):
		_on_card_hover(card)
	_refresh_z()

func _is_mouse_over_card(card: Control) -> bool:
	return card.get_global_rect().has_point(get_viewport().get_mouse_position())

func _is_mouse_inside_hand() -> bool:
	if hand_area == null:
		return false
	return hand_area.get_global_rect().has_point(get_viewport().get_mouse_position())

func _update_drag_hover_state() -> void:
	if dragging_card == null or !is_instance_valid(dragging_card):
		_dragging_inside_hand = false
		return
	_dragging_inside_hand = _is_mouse_inside_hand()
	if !_dragging_inside_hand and _current_energy <= 0:
		SoundManager.play_sfx("HandviewNoCostError")
		var cancelled: Card = dragging_card
		cancelled.cardCurrentState = Card.cardState.following
		end_drag(cancelled, false)
		if is_instance_valid(cancelled):
			cancelled._set_other_cards_mouse_filter(false)
		return
	if _dragging_inside_hand:
		if hovered_card != dragging_card:
			hovered_card = dragging_card
			dragging_card.set_hover_visuals(true)
	else:
		if hovered_card == dragging_card:
			hovered_card = null
		dragging_card.set_hover_visuals(false)

func _apply_hand_scale() -> void:
	if is_instance_valid(hand_root):
		hand_root.scale = _base_hand_scale * hand_scale

func _on_resource_changed(energy: int, _flips_left: int, _context: Dictionary) -> void:
	_current_energy = energy
