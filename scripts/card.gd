extends Control
class_name Card

enum cardState { following, dragging }

var velocity: Vector2 = Vector2.ZERO
var damping: float = 0.45
var stiffness: float = 500.0

@export_group("Drag")
@export var dir_move_duration: float = 0.1
@export var drag_follow_speed: float = 100
@export_group("")

var cardCurrentState: cardState = cardState.following
var follow_target: CanvasItem = null

@onready var desc_panel: Panel = $DescPanel
@onready var desc_label: Label = $DescPanel/DescLabel
@onready var name_label: Label = $Control/name
@onready var item_img: TextureRect = $Control/itemImg
@onready var dir_n: Control = $DirNums/N
@onready var dir_e: Control = $DirNums/E
@onready var dir_s: Control = $DirNums/S
@onready var dir_w: Control = $DirNums/W

var _base_width: float = 0.0
var _hovered_visual: bool = false
var _dir_layouts: Dictionary = {}
var _layout_tweens: Dictionary = {}
var card_display_name: String = ""
var card_numbers: DirectionNumbers = DirectionNumbers.new()
var card_id: int = -1
var card_effect_id: String = ""
var card_desc_text: String = ""
var card_art: Texture2D = null
var card_art_flipped: Texture2D = null
var _drag_prev_z: int = 0
var _ui_ready: bool = false

func _ready() -> void:
	_base_width = custom_minimum_size.x if custom_minimum_size.x > 0.0 else size.x
	_store_dir_layouts()
	if is_instance_valid(desc_panel):
		desc_panel.visible = false
	if is_instance_valid(name_label):
		name_label.visible = true
	_sync_layout()
	_ui_ready = true
	_apply_card_data_to_ui()
	var btn: Button = get_node_or_null("Button") as Button
	if btn != null:
		btn.mouse_entered.connect(_on_button_mouse_entered)
		btn.mouse_exited.connect(_on_button_mouse_exited)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	match cardCurrentState:
		cardState.dragging:
			var local_center: Vector2 = size * 0.5
			var global_rect: Rect2 = get_global_rect()
			var center: Vector2 = global_rect.position + global_rect.size * 0.5
			var offset: Vector2 = center - global_position
			var target_position: Vector2 = get_global_mouse_position() - offset
			var t: float = 1.0 - pow(0.001, delta * drag_follow_speed)
			global_position = global_position.lerp(target_position, t)
		cardState.following:
			if follow_target != null and is_instance_valid(follow_target):
				var target_position: Vector2 = follow_target.global_position
				var displacement: Vector2 = target_position - global_position
				var force: Vector2 = displacement * stiffness
				velocity += force * delta
				velocity *= (1.0 - damping)
				global_position += velocity * delta
	if cardCurrentState == cardState.following and follow_target != null:
		var target_position = follow_target.global_position
		var displacement = target_position - global_position
		var force = displacement * stiffness
		velocity += force * delta
		velocity *= (1.0 - damping)
		global_position += velocity * delta

func set_card_data(display_name: String, n: int, e: int, s: int, w: int) -> void:
	card_display_name = display_name
	card_numbers.set_value("n", n)
	card_numbers.set_value("e", e)
	card_numbers.set_value("s", s)
	card_numbers.set_value("w", w)
	if _ui_ready:
		_apply_card_data_to_ui()

func set_direction_numbers(numbers: DirectionNumbers) -> void:
	card_numbers = numbers.clone()
	if _ui_ready:
		_apply_card_data_to_ui()

func get_direction_numbers() -> DirectionNumbers:
	return card_numbers.clone()

func get_card_data() -> Dictionary:
	return {
		"card_id": card_id,
		"display_name": card_display_name,
		"n": card_numbers.get_value("n"),
		"e": card_numbers.get_value("e"),
		"s": card_numbers.get_value("s"),
		"w": card_numbers.get_value("w"),
		"numbers": card_numbers.to_dict(),
		"effect_id": card_effect_id,
		"desc": card_desc_text,
	}

func set_desc_text(text: String) -> void:
	card_desc_text = text
	if _ui_ready:
		desc_label.text = text

func set_art(texture: Texture2D, flipped: Texture2D = null) -> void:
	card_art = texture
	card_art_flipped = flipped
	item_img.texture = card_art

func get_card_art() -> Texture2D:
	return card_art

func get_card_art_flipped() -> Texture2D:
	return card_art_flipped

func _apply_card_data_to_ui() -> void:
	name_label.text = card_display_name
	_set_dir_value(dir_n, card_numbers.get_value("n"))
	_set_dir_value(dir_e, card_numbers.get_value("e"))
	_set_dir_value(dir_s, card_numbers.get_value("s"))
	_set_dir_value(dir_w, card_numbers.get_value("w"))
	desc_label.text = card_desc_text

func rotate_direction_numbers(is_clockwise: bool, times: int = 1) -> void:
	var steps: int = times % 4
	if steps < 0:
		steps += 4
	if steps == 0:
		return
	for _i in range(steps):
		var old_n: int = card_numbers.get_value("n")
		var old_e: int = card_numbers.get_value("e")
		var old_s: int = card_numbers.get_value("s")
		var old_w: int = card_numbers.get_value("w")
		if is_clockwise:
			card_numbers.set_value("n", old_w)
			card_numbers.set_value("e", old_n)
			card_numbers.set_value("s", old_e)
			card_numbers.set_value("w", old_s)
		else:
			card_numbers.set_value("n", old_e)
			card_numbers.set_value("e", old_s)
			card_numbers.set_value("s", old_w)
			card_numbers.set_value("w", old_n)
	_set_dir_value(dir_n, card_numbers.get_value("n"))
	_set_dir_value(dir_e, card_numbers.get_value("e"))
	_set_dir_value(dir_s, card_numbers.get_value("s"))
	_set_dir_value(dir_w, card_numbers.get_value("w"))

func _set_dir_value(node: Control, value: int) -> void:
	var label: Label = node.get_node_or_null("Value") as Label
	label.text = str(value)

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_sync_layout()
		if _hovered_visual:
			_apply_hover_dir_layouts(false)

func _sync_layout() -> void:
	var width: float = _base_width if _base_width > 0.0 else size.x
	var height: float = custom_minimum_size.y if custom_minimum_size.y > 0.0 else size.y
	if width <= 0.0 or height <= 0.0:
		return
	pivot_offset = Vector2(width * 0.5, height)

func set_hover_visuals(hovered: bool) -> void:
	_hovered_visual = hovered
	if is_instance_valid(desc_panel):
		desc_panel.visible = hovered
	if hovered:
		_apply_hover_dir_layouts(true)
	else:
		_restore_dir_layouts(true)

func _on_button_mouse_entered() -> void:
	set_hover_visuals(true)
	SoundManager.play_sfx("CardHover")

func _on_button_mouse_exited() -> void:
	if cardCurrentState != cardState.dragging:
		set_hover_visuals(false)

func _store_dir_layouts() -> void:
	_dir_layouts.clear()
	_dir_layouts["N"] = _capture_layout(dir_n)
	_dir_layouts["E"] = _capture_layout(dir_e)
	_dir_layouts["S"] = _capture_layout(dir_s)
	_dir_layouts["W"] = _capture_layout(dir_w)

func _capture_layout(node: Control) -> Dictionary:
	return {
		"anchor_left": node.anchor_left,
		"anchor_top": node.anchor_top,
		"anchor_right": node.anchor_right,
		"anchor_bottom": node.anchor_bottom,
		"offset_left": node.offset_left,
		"offset_top": node.offset_top,
		"offset_right": node.offset_right,
		"offset_bottom": node.offset_bottom,
		"grow_horizontal": node.grow_horizontal,
		"grow_vertical": node.grow_vertical,
	}

func _restore_dir_layouts(tween: bool) -> void:
	_apply_layout(dir_n, _dir_layouts.get("N", {}), tween)
	_apply_layout(dir_e, _dir_layouts.get("E", {}), tween)
	_apply_layout(dir_s, _dir_layouts.get("S", {}), tween)
	_apply_layout(dir_w, _dir_layouts.get("W", {}), tween)

func _apply_layout(node: Control, data: Dictionary, tween: bool) -> void:
	if data.is_empty():
		return
	if tween:
		_tween_layout(node, data)
	else:
		node.anchor_left = float(data.get("anchor_left", node.anchor_left))
		node.anchor_top = float(data.get("anchor_top", node.anchor_top))
		node.anchor_right = float(data.get("anchor_right", node.anchor_right))
		node.anchor_bottom = float(data.get("anchor_bottom", node.anchor_bottom))
		node.offset_left = float(data.get("offset_left", node.offset_left))
		node.offset_top = float(data.get("offset_top", node.offset_top))
		node.offset_right = float(data.get("offset_right", node.offset_right))
		node.offset_bottom = float(data.get("offset_bottom", node.offset_bottom))
		node.grow_horizontal = int(data.get("grow_horizontal", node.grow_horizontal))
		node.grow_vertical = int(data.get("grow_vertical", node.grow_vertical))

func _apply_hover_dir_layouts(tween: bool) -> void:
	_apply_layout(dir_n, _edge_layout(dir_n, 0), tween) # top
	_apply_layout(dir_e, _edge_layout(dir_e, 1), tween) # right
	_apply_layout(dir_s, _edge_layout(dir_s, 2), tween) # bottom
	_apply_layout(dir_w, _edge_layout(dir_w, 3), tween) # left

func _get_node_size(node: Control) -> Vector2:
	var size_vec: Vector2 = node.size
	if size_vec.x <= 0.0 or size_vec.y <= 0.0:
		size_vec = node.custom_minimum_size
	return size_vec

func _edge_layout(node: Control, edge: int) -> Dictionary:
	var sz: Vector2 = _get_node_size(node)
	var data: Dictionary = {
		"grow_horizontal": node.grow_horizontal,
		"grow_vertical": node.grow_vertical,
	}
	match edge:
		0: # top center
			data["anchor_left"] = 0.5
			data["anchor_right"] = 0.5
			data["anchor_top"] = 0.0
			data["anchor_bottom"] = 0.0
			data["offset_left"] = -sz.x * 0.5
			data["offset_right"] = sz.x * 0.5
			data["offset_top"] = 0.0
			data["offset_bottom"] = sz.y
		1: # right center
			data["anchor_left"] = 1.0
			data["anchor_right"] = 1.0
			data["anchor_top"] = 0.5
			data["anchor_bottom"] = 0.5
			data["offset_left"] = -sz.x
			data["offset_right"] = 0.0
			data["offset_top"] = -sz.y * 0.5
			data["offset_bottom"] = sz.y * 0.5
		2: # bottom center
			data["anchor_left"] = 0.5
			data["anchor_right"] = 0.5
			data["anchor_top"] = 1.0
			data["anchor_bottom"] = 1.0
			data["offset_left"] = -sz.x * 0.5
			data["offset_right"] = sz.x * 0.5
			data["offset_top"] = -sz.y
			data["offset_bottom"] = 0.0
		3: # left center
			data["anchor_left"] = 0.0
			data["anchor_right"] = 0.0
			data["anchor_top"] = 0.5
			data["anchor_bottom"] = 0.5
			data["offset_left"] = 0.0
			data["offset_right"] = sz.x
			data["offset_top"] = -sz.y * 0.5
			data["offset_bottom"] = sz.y * 0.5
	return data

func _tween_layout(node: Control, data: Dictionary) -> void:
	var existing: Tween = _layout_tweens.get(node, null) as Tween
	if existing != null:
		existing.kill()
	node.grow_horizontal = int(data.get("grow_horizontal", node.grow_horizontal))
	node.grow_vertical = int(data.get("grow_vertical", node.grow_vertical))
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_parallel()
	_layout_tweens[node] = tween
	var duration: float = dir_move_duration
	tween.tween_property(node, "anchor_left", float(data.get("anchor_left", node.anchor_left)), duration)
	tween.tween_property(node, "anchor_top", float(data.get("anchor_top", node.anchor_top)), duration)
	tween.tween_property(node, "anchor_right", float(data.get("anchor_right", node.anchor_right)), duration)
	tween.tween_property(node, "anchor_bottom", float(data.get("anchor_bottom", node.anchor_bottom)), duration)
	tween.tween_property(node, "offset_left", float(data.get("offset_left", node.offset_left)), duration)
	tween.tween_property(node, "offset_top", float(data.get("offset_top", node.offset_top)), duration)
	tween.tween_property(node, "offset_right", float(data.get("offset_right", node.offset_right)), duration)
	tween.tween_property(node, "offset_bottom", float(data.get("offset_bottom", node.offset_bottom)), duration)


func _on_button_button_down() -> void:
	cardCurrentState = cardState.dragging
	velocity = Vector2.ZERO
	_drag_prev_z = z_index
	z_index = 1000
	_set_other_cards_mouse_filter(true)
	var hand: HandView = _get_hand_view()
	if hand != null:
		hand.begin_drag(self)
	pass # Replace with function body.

func _on_button_button_up() -> void:
	if cardCurrentState == cardState.dragging:
		var hand: HandView = _get_hand_view()
		if hand != null:
			hand.end_drag(self)
		_set_other_cards_mouse_filter(false)
		z_index = _drag_prev_z
		if _try_place_on_cell():
			return
	cardCurrentState = cardState.following
	pass # Replace with function body.

func _try_place_on_cell() -> bool:
	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	var cells: Array = get_tree().get_nodes_in_group("cells")
	for cell in cells:
		var cell_control: Cell = cell as Cell
		if cell_control == null or !cell_control.is_visible_in_tree():
			continue
		if cell_control.get_global_rect().has_point(mouse_pos):
			var placed: bool = cell_control.place_card(self)
			if placed:
				_remove_from_hand()
				return true
	return false

func _get_hand_view() -> HandView:
	var node: Node = get_parent()
	while node != null:
		if node is HandView:
			return node as HandView
		node = node.get_parent()
	return null

func _set_other_cards_mouse_filter(ignore: bool) -> void:
	var hand: HandView = _get_hand_view()
	if hand == null:
		return
	for card_node in hand.cards:
		var other: Card = card_node as Card
		if other == null or other == self:
			continue
		var btn: Button = other.get_node_or_null("Button") as Button
		if btn == null:
			continue
		if ignore:
			if !btn.has_meta("prev_mouse_filter"):
				btn.set_meta("prev_mouse_filter", btn.mouse_filter)
			btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
		else:
			if btn.has_meta("prev_mouse_filter"):
				btn.mouse_filter = int(btn.get_meta("prev_mouse_filter"))
				btn.remove_meta("prev_mouse_filter")
			else:
				btn.mouse_filter = Control.MOUSE_FILTER_STOP

func _remove_from_hand() -> void:
	var node: Node = get_parent()
	while node != null:
		if node is HandView:
			(node as HandView).remove_card(self)
			return
		node = node.get_parent()
	queue_free()
