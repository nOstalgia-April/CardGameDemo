extends Control

@export var card_scene: PackedScene
@export var initial_card_count: int = 3

@export var hand_width: float = 900.0
@export var default_spacing: float = 180.0
@export var fan_angle_deg: float = 40.0
@export var max_card_angle_deg: float = 5.0
@export var fan_stop_cards: int = 8
@export var curve_height: float = 90.0
@export var bottom_padding: float = 16.0

@export var hover_raise: float = 60.0
@export var hover_scale: float = 1.0
@export var hover_spread: float = 24.0
@export var hover_rotation_factor: float = 0.6

@export var follow_speed: float = 12.0
@export var hand_scale: float = 1.0

@onready var hand_root: Control = $HandRoot
@onready var hand_area: Control = $HandRoot/HandArea
@onready var card_container: Control = $HandRoot/CardContainer

var cards: Array[Control] = []
var hovered_card: Control = null

func _ready() -> void:
	_apply_hand_scale()
	if card_scene == null:
		card_scene = preload("res://tscns/card.tscn")
	for i in range(initial_card_count):
		add_card()

func add_card() -> Control:
	var card: Control = card_scene.instantiate()
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

func _setup_card(card: Control) -> void:
	card.set_anchors_preset(Control.PRESET_TOP_LEFT)
	card.z_as_relative = true
	var btn: Button = card.get_node_or_null("Button") as Button
	if btn != null:
		btn.mouse_entered.connect(_on_card_hover.bind(card))
		btn.mouse_exited.connect(_on_card_unhover.bind(card))

func _on_card_hover(card: Control) -> void:
	hovered_card = card
	_refresh_z()

func _on_card_unhover(card: Control) -> void:
	if hovered_card == card:
		hovered_card = null
		_refresh_z()

func _process(delta: float) -> void:
	if hovered_card != null and !is_instance_valid(hovered_card):
		hovered_card = null
	_update_layout(delta)

func _update_layout(delta: float) -> void:
	if cards.is_empty():
		return

	var count := cards.size()
	var area_size := hand_area.size
	var area_pos := hand_area.position

	var max_width: float = min(hand_width, area_size.x)
	var spacing := 0.0
	if count > 1:
		spacing = min(default_spacing, max_width / float(count - 1))
	var total_width := spacing * float(count - 1)

	var center_x := area_pos.x + area_size.x * 0.5
	var base_y := area_pos.y + area_size.y - bottom_padding

	var angle_span := fan_angle_deg
	if fan_stop_cards > 1:
		var t_span: float = min(1.0, float(count - 1) / float(fan_stop_cards - 1))
		angle_span = fan_angle_deg * t_span
	var span_factor: float = sin(deg_to_rad(angle_span * 0.5))
	var effective_curve_height: float = curve_height * span_factor

	var hovered_index := -1
	if hovered_card != null:
		hovered_index = cards.find(hovered_card)

	for i in range(count):
		var card := cards[i]
		if !is_instance_valid(card):
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
		_set_card_expanded(card, is_hovered, is_hovered)

		var target_pos := Vector2(x, y) - card.pivot_offset
		var target_scale := Vector2.ONE
		var target_rot := rot
		var target_z := i

		if hovered_card != null and hovered_index >= 0:
			if is_hovered:
				var compact_h: float = _get_card_compact_height(card)
				var expanded_h: float = _get_card_expanded_height(card)
				var center_down: float = max(0.0, (expanded_h - compact_h) * 0.5)
				target_pos += Vector2(0, center_down - hover_raise)
				if hover_scale != 1.0:
					target_scale = Vector2(1.0, hover_scale)
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

func _set_card_expanded(card: Control, expanded: bool, instant: bool) -> void:
	if card.has_method("set_expanded"):
		card.call("set_expanded", expanded, instant)

func _get_card_compact_height(card: Control) -> float:
	if card.has_method("get_compact_height"):
		return float(card.call("get_compact_height"))
	return card.custom_minimum_size.y

func _get_card_expanded_height(card: Control) -> float:
	if card.has_method("get_expanded_height"):
		return float(card.call("get_expanded_height"))
	return card.custom_minimum_size.y

func _refresh_z() -> void:
	for i in range(cards.size()):
		var card := cards[i]
		if is_instance_valid(card):
			card.z_index = i

func _apply_hand_scale() -> void:
	if is_instance_valid(hand_root):
		hand_root.scale = Vector2.ONE * hand_scale
