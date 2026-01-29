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
	# 设置 Panel 样式
	if tooltip_panel != null:
		var panel_style: StyleBoxFlat = StyleBoxFlat.new()
		panel_style.bg_color = Color(0.1, 0.1, 0.18, 0.95)  # 深蓝黑半透明
		panel_style.border_width_left = 2
		panel_style.border_width_top = 2
		panel_style.border_width_right = 2
		panel_style.border_width_bottom = 2
		panel_style.border_color = Color(1.0, 0.843, 0.0, 1.0)  # 金色边框
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

	# 设置 NameLabel 样式
	if name_label != null:
		var name_settings: LabelSettings = LabelSettings.new()
		name_settings.font_size = 22
		name_settings.font_color = Color(1.0, 0.843, 0.0, 1.0)  # 金色
		name_label.label_settings = name_settings
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	# 设置 DescLabel 样式
	if desc_label != null:
		var desc_settings: LabelSettings = LabelSettings.new()
		desc_settings.font_size = 15
		desc_settings.font_color = Color(0.875, 0.875, 0.875, 1.0)  # 米白色
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

	var global_rect: Rect2 = context.get("global_rect", Rect2())
	
	# 获取卡牌的全局位置和大小
	var card_global_pos = global_rect.position
	var card_size = global_rect.size
	
	# 获取Board节点以确定中心格子位置
	var board = _get_board_node()
	if board != null:
		# 获取中心格子位置（通常是(0,0)）
		var center_cell = board.get_cell_at(Vector2i(0, 0))
		var center_pos = Vector2.ZERO
		if center_cell != null:
			center_pos = center_cell.global_position
		
		# 计算卡牌相对于中心格子的坐标
		var card_pos = _get_card_cell_position(board, card_global_pos)
		var relative_pos = card_pos - Vector2i(0, 0)  # 中心格子是(0,0)
		
		# 根据九宫格位置决定弹窗显示位置，确保弹窗紧贴棋子边缘
		# 九宫格布局：
		# (0,0) (1,0) (2,0)
		# (0,1) (1,1) (2,1)
		# (0,2) (1,2) (2,2)

		match relative_pos:
			Vector2i(0, 0):
				# 第一格：弹窗右下角重合于卡牌左上角
				tooltip_panel.global_position = Vector2(card_global_pos.x - tooltip_panel.size.x, card_global_pos.y - tooltip_panel.size.y)
			Vector2i(1, 0):
				# 第二格：弹窗下边紧贴卡牌上边
				tooltip_panel.global_position = Vector2(card_global_pos.x + (card_size.x - tooltip_panel.size.x) / 2, card_global_pos.y - tooltip_panel.size.y)
			Vector2i(2, 0):
				# 第三格：弹窗左下角重合于卡牌右上角
				tooltip_panel.global_position = Vector2(card_global_pos.x + card_size.x, card_global_pos.y - tooltip_panel.size.y)
			Vector2i(0, 1):
				# 第四格：弹窗右边紧贴卡牌左边
				tooltip_panel.global_position = Vector2(card_global_pos.x - tooltip_panel.size.x, card_global_pos.y)
			Vector2i(1, 1):
				# 第五格：弹窗显示在第六格的右边
				# 获取第六格的位置
				var sixth_cell_pos = board.get_cell_at(Vector2i(2, 1))
				if sixth_cell_pos != null:
					tooltip_panel.global_position = Vector2(sixth_cell_pos.global_position.x + sixth_cell_pos.size.x, sixth_cell_pos.global_position.y)
				else:
					# 如果找不到第六格，则显示在当前卡牌右边
					tooltip_panel.global_position = Vector2(card_global_pos.x + card_size.x, card_global_pos.y)
			Vector2i(2, 1):
				# 第六格：弹窗左边紧贴卡牌右边
				tooltip_panel.global_position = Vector2(card_global_pos.x + card_size.x, card_global_pos.y)
			Vector2i(0, 2):
				# 第七格：弹窗右上角重合于卡牌左下角
				tooltip_panel.global_position = Vector2(card_global_pos.x - tooltip_panel.size.x, card_global_pos.y + card_size.y)
			Vector2i(1, 2):
				# 第八格：弹窗上边紧贴卡牌下边
				tooltip_panel.global_position = Vector2(card_global_pos.x + (card_size.x - tooltip_panel.size.x) / 2, card_global_pos.y + card_size.y)
			Vector2i(2, 2):
				# 第九格：弹窗左上角重合于卡牌右下角
				tooltip_panel.global_position = Vector2(card_global_pos.x + card_size.x, card_global_pos.y + card_size.y)
			_:
				# 默认情况：弹窗显示在棋子右侧
				tooltip_panel.global_position = Vector2(card_global_pos.x + card_size.x, card_global_pos.y)

		# 输出调试信息
		print("棋子位置: ", card_global_pos)
		print("棋子大小: ", card_size)
		print("弹窗位置: ", global_position)
		print("弹窗大小: ", tooltip_panel.size)
		print("相对位置: ", relative_pos)
	else:
		# 如果找不到Board节点，则使用原始方法
		global_position = card_global_pos

	tooltip_panel.visible = true

func _on_unit_hover_ended() -> void:
	if tooltip_panel != null:
		tooltip_panel.visible = false

# 辅助函数：获取Board节点
func _get_board_node() -> Board:
	# 遍历场景树查找Board节点
	var root = get_tree().root
	var board = _find_board_recursive(root)
	return board

func _get_card_cell_position(board: Board, card_global_pos: Vector2) -> Vector2i:
	# 遍历所有单元格，找到包含指定卡牌位置的单元格
	for cell in board._get_all_cells():
		var cell_global_rect = Rect2(cell.global_position, cell.size)
		if cell_global_rect.has_point(card_global_pos):
			return board.get_cell_pos(cell)
	return Vector2i(0, 0)  # 默认返回中心位置

# 递归查找Board节点的辅助函数
func _find_board_recursive(node: Node) -> Board:
	if node is Board:
		return node
	
	for child in node.get_children():
		var result = _find_board_recursive(child)
		if result != null:
			return result
	return null