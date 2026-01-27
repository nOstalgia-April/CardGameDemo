extends Control

enum cardState { following, dragging }

var velocity: Vector2 = Vector2.ZERO
var damping: float = 0.35
var stiffness: float = 500.0

@export var cardCurrentState: cardState = cardState.following
@export var follow_target: CanvasItem

@export var compact_height: float = 240.0
@export var expanded_height: float = 340.0
@export var desc_height_ratio: float = 0.35
@export var size_lerp_speed: float = 12.0

@onready var desc_panel: Panel = $DescPanel
@onready var desc_label: Label = $DescPanel/DescLabel
@onready var name_label: Label = $Control/ColorRect/name
@onready var dir_n: Control = $DirNums/N
@onready var dir_e: Control = $DirNums/E
@onready var dir_s: Control = $DirNums/S
@onready var dir_w: Control = $DirNums/W

var _target_height: float = 0.0
var _base_width: float = 0.0
var card_display_name: String = ""
var card_n: int = 0
var card_e: int = 0
var card_s: int = 0
var card_w: int = 0

func _ready() -> void:
	_base_width = custom_minimum_size.x if custom_minimum_size.x > 0.0 else size.x
	_target_height = compact_height
	set_expanded(false, true)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	match cardCurrentState:
		cardState.dragging:
			var target_position = get_global_mouse_position()-size/2
			global_position=global_position.lerp(target_position,0.4)
		cardState.following:
			if follow_target!=null:
				var target_position = follow_target.global_position
				var displacement = target_position - global_position
				var force = displacement*stiffness
				velocity += force*delta
				velocity *= (1.0-damping)
				global_position += velocity * delta
	_update_size(delta)

func set_expanded(expanded: bool, instant: bool) -> void:
	_target_height = expanded_height if expanded else compact_height
	if is_instance_valid(desc_panel):
		desc_panel.visible = expanded
	if is_instance_valid(name_label):
		name_label.visible = expanded
	if instant:
		_apply_height(_target_height)

func set_card_data(display_name: String, n: int, e: int, s: int, w: int) -> void:
	card_display_name = display_name
	card_n = n
	card_e = e
	card_s = s
	card_w = w
	if is_instance_valid(name_label):
		name_label.text = display_name
	_set_dir_value(dir_n, n)
	_set_dir_value(dir_e, e)
	_set_dir_value(dir_s, s)
	_set_dir_value(dir_w, w)

func get_card_data() -> Dictionary:
	return {
		"display_name": card_display_name,
		"n": card_n,
		"e": card_e,
		"s": card_s,
		"w": card_w,
	}

func _set_dir_value(node: Control, value: int) -> void:
	var label: Label = node.get_node("Value") as Label
	if label != null:
		label.text = str(value)

func get_compact_height() -> float:
	return compact_height

func get_expanded_height() -> float:
	return expanded_height

func _update_size(delta: float) -> void:
	if is_equal_approx(size.y, _target_height):
		return
	var t: float = 1.0 - pow(0.001, delta * size_lerp_speed)
	var new_h: float = lerp(size.y, _target_height, t)
	_apply_height(new_h)

func _apply_height(height: float) -> void:
	var width: float = _base_width
	custom_minimum_size = Vector2(width, height)
	size = Vector2(width, height)
	pivot_offset = Vector2(width * 0.5, height)
	_update_desc_panel(width, height)

func _update_desc_panel(width: float, height: float) -> void:
	if !is_instance_valid(desc_panel):
		return
	var desc_h: float = height * desc_height_ratio
	desc_panel.position = Vector2(0.0, height - desc_h)
	desc_panel.size = Vector2(width, desc_h)
	if is_instance_valid(desc_label):
		desc_label.size = desc_panel.size

func _on_button_button_down() -> void:
	cardCurrentState = cardState.dragging
	pass # Replace with function body.

func _on_button_button_up() -> void:
	if cardCurrentState == cardState.dragging:
		if _try_place_on_cell():
			return
	cardCurrentState = cardState.following
	pass # Replace with function body.

func _try_place_on_cell() -> bool:
	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	var cells: Array = get_tree().get_nodes_in_group("cells")
	for cell in cells:
		var cell_control: Control = cell as Control
		if cell_control == null or !cell_control.is_visible_in_tree():
			continue
		if cell_control.get_global_rect().has_point(mouse_pos):
			if cell_control.has_method("place_card"):
				var placed: bool = bool(cell_control.call("place_card", self))
				if placed:
					_remove_from_hand()
					return true
	return false

func _remove_from_hand() -> void:
	var node: Node = get_parent()
	while node != null:
		if node.has_method("remove_card"):
			node.call("remove_card", self)
			return
		node = node.get_parent()
	queue_free()
