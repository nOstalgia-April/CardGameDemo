extends Control
class_name CardTooltipManager

@onready var tooltip_panel: Panel = $TooltipPanel
@onready var name_label: Label = $TooltipPanel/VBoxContainer/NameLabel
@onready var desc_label: Label = $TooltipPanel/VBoxContainer/DescLabel

func _ready() -> void:
	_setup_styles()
	if tooltip_panel != null:
		tooltip_panel.visible = false
	BattleEventBus.connect("unit_hover_started", _on_unit_hover_started)
	BattleEventBus.connect("unit_hover_ended", _on_unit_hover_ended)

func _setup_styles() -> void:
	if tooltip_panel != null:
		var panel_style: StyleBoxFlat = StyleBoxFlat.new()
		panel_style.bg_color = Color(0.1, 0.1, 0.18, 0.95)
		panel_style.border_width_left = 2
		panel_style.border_width_top = 2
		panel_style.border_width_right = 2
		panel_style.border_width_bottom = 2
		panel_style.border_color = Color(1.0, 0.843, 0.0, 1.0)
		panel_style.corner_radius_top_left = 5
		panel_style.corner_radius_top_right = 5
		panel_style.corner_radius_bottom_left = 5
		panel_style.corner_radius_bottom_right = 5
		panel_style.content_margin_left = 15
		panel_style.content_margin_top = 15
		panel_style.content_margin_right = 15
		panel_style.content_margin_bottom = 15
		panel_style.shadow_color = Color(0, 0, 0, 0.5)
		panel_style.shadow_size = 5
		panel_style.shadow_offset = Vector2(2, 2)
		tooltip_panel.add_theme_stylebox_override("panel", panel_style)

	if name_label != null:
		var name_settings: LabelSettings = LabelSettings.new()
		name_settings.font_size = 22
		name_settings.font_color = Color(1.0, 0.843, 0.0, 1.0)
		name_label.label_settings = name_settings
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	if desc_label != null:
		var desc_settings: LabelSettings = LabelSettings.new()
		desc_settings.font_size = 15
		desc_settings.font_color = Color(0.875, 0.875, 0.875, 1.0)
		desc_settings.line_spacing = 4
		desc_label.label_settings = desc_settings
		desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		desc_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

func _on_unit_hover_started(context: Dictionary) -> void:
	if tooltip_panel == null:
		return
	if name_label != null:
		name_label.text = context.get("name", "")
	if desc_label != null:
		desc_label.text = context.get("desc", "")

	await get_tree().process_frame
	var content: Control = $TooltipPanel/VBoxContainer
	var content_size: Vector2 = content.get_combined_minimum_size()
	var padded_size: Vector2 = content_size + Vector2(30, 30)
	tooltip_panel.size = Vector2(
		max(tooltip_panel.size.x, padded_size.x),
		max(tooltip_panel.size.y, padded_size.y)
	)

	var global_rect: Rect2 = context.get("global_rect", Rect2())
	var card_global_pos: Vector2 = global_rect.position
	var card_size: Vector2 = global_rect.size
	var board := _get_board_node()
	if board != null:
		var bounds: Dictionary = _get_board_bounds(board)
		var center_pos: Vector2i = bounds.get("center", Vector2i.ZERO)
		var card_pos: Vector2i = _get_card_cell_position(board, global_rect.get_center())
		var relative_pos: Vector2i = card_pos - center_pos

		match relative_pos:
			Vector2i(-1, -1):
				tooltip_panel.global_position = Vector2(card_global_pos.x - tooltip_panel.size.x, card_global_pos.y - tooltip_panel.size.y)
			Vector2i(0, -1):
				tooltip_panel.global_position = Vector2(card_global_pos.x + (card_size.x - tooltip_panel.size.x) / 2, card_global_pos.y - tooltip_panel.size.y)
			Vector2i(1, -1):
				tooltip_panel.global_position = Vector2(card_global_pos.x + card_size.x, card_global_pos.y - tooltip_panel.size.y)
			Vector2i(-1, 0):
				tooltip_panel.global_position = Vector2(card_global_pos.x - tooltip_panel.size.x, card_global_pos.y)
			Vector2i(0, 0):
				var max_pos: Vector2i = bounds.get("max", center_pos)
				var right_cell: Cell = board.get_cell_at(Vector2i(max_pos.x, center_pos.y))
				if right_cell != null:
					tooltip_panel.global_position = Vector2(right_cell.global_position.x + right_cell.size.x, right_cell.global_position.y)
				else:
					tooltip_panel.global_position = Vector2(card_global_pos.x + card_size.x, card_global_pos.y)
			Vector2i(1, 0):
				tooltip_panel.global_position = Vector2(card_global_pos.x + card_size.x, card_global_pos.y)
			Vector2i(-1, 1):
				tooltip_panel.global_position = Vector2(card_global_pos.x - tooltip_panel.size.x, card_global_pos.y + card_size.y)
			Vector2i(0, 1):
				tooltip_panel.global_position = Vector2(card_global_pos.x + (card_size.x - tooltip_panel.size.x) / 2, card_global_pos.y + card_size.y)
			Vector2i(1, 1):
				tooltip_panel.global_position = Vector2(card_global_pos.x + card_size.x, card_global_pos.y + card_size.y)
			_:
				tooltip_panel.global_position = Vector2(card_global_pos.x + card_size.x, card_global_pos.y)
	else:
		tooltip_panel.global_position = Vector2(card_global_pos.x + card_size.x, card_global_pos.y)

	tooltip_panel.visible = true

func _on_unit_hover_ended() -> void:
	if tooltip_panel != null:
		tooltip_panel.visible = false

func _get_board_node() -> Board:
	var root := get_tree().root
	return _find_board_recursive(root)

func _get_board_bounds(board: Board) -> Dictionary:
	var min_x := 1_000_000
	var min_y := 1_000_000
	var max_x := -1_000_000
	var max_y := -1_000_000
	for cell in board._get_all_cells():
		var pos: Vector2i = board.get_cell_pos(cell)
		min_x = min(min_x, pos.x)
		min_y = min(min_y, pos.y)
		max_x = max(max_x, pos.x)
		max_y = max(max_y, pos.y)
	var center := Vector2i(int((min_x + max_x) / 2), int((min_y + max_y) / 2))
	return {
		"min": Vector2i(min_x, min_y),
		"max": Vector2i(max_x, max_y),
		"center": center,
	}

func _get_card_cell_position(board: Board, card_center: Vector2) -> Vector2i:
	for cell in board._get_all_cells():
		var cell_global_rect := Rect2(cell.global_position, cell.size)
		if cell_global_rect.has_point(card_center):
			return board.get_cell_pos(cell)
	return Vector2i.ZERO

func _find_board_recursive(node: Node) -> Board:
	if node is Board:
		return node
	for child in node.get_children():
		var result: Board = _find_board_recursive(child)
		if result != null:
			return result
	return null
