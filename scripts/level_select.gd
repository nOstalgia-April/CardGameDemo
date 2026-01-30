extends Node2D

# 引用 Board 节点
@onready var board: Board = $Root/Board
@onready var grid: GridContainer = $Root/Board/GridContainer

# 引用 FancyBackButton 和 CoverImage
@onready var fancy_back_button: TextureButton = $CanvasLayer/BackAnchor/FancyBackButton
@onready var cover_image: TextureRect = $CanvasLayer/BackAnchor/FancyBackButton/CoverImage

# 引用 Board 下所有 Cell 里的 Highlight 节点
@onready var cell_highlights: Array[Panel] = []

# 最大解锁关卡数
var max_unlocked_level: int = 2  # 暂时手动设为2，方便测试

# CoverImage 的初始坐标
var cover_origin: Vector2

# 全局输入检测函数
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("[LevelSelect] 全局检测到点击，位置: ", event.position)

		# 获取鼠标位置
		var mouse_pos = get_viewport().get_mouse_position()
		print("[LevelSelect] 鼠标位置: ", mouse_pos)

		# 打印场景树结构
		print("[LevelSelect] Board 子节点: ", board.get_child_count())
		for i in range(board.get_child_count()):
			print("[LevelSelect]  - 子节点 ", i, ": ", board.get_child(i).name)

		print("[LevelSelect] GridContainer 子节点: ", grid.get_child_count())
		for i in range(grid.get_child_count()):
			var child = grid.get_child(i)
			print("[LevelSelect]  - 子节点 ", i, ": ", child.name, " 类型: ", child.get_class())
			# 检查是否是 Control 节点
			if child is Control:
				var global_rect = child.get_global_rect()
				print("[LevelSelect]    - 全局矩形: ", global_rect)
				print("[LevelSelect]    - 鼠标在矩形内: ", global_rect.has_point(mouse_pos))
				print("[LevelSelect]    - mouse_filter: ", child.mouse_filter)
				print("[LevelSelect]    - visible: ", child.visible)

				# 检查 Cell 的子节点
				print("[LevelSelect]    - 子节点数量: ", child.get_child_count())
				for j in range(child.get_child_count()):
					var sub_child = child.get_child(j)
					print("[LevelSelect]      - 子节点 ", j, ": ", sub_child.name, " 类型: ", sub_child.get_class())
					if sub_child is Control:
						var sub_rect = sub_child.get_global_rect()
						print("[LevelSelect]        - 全局矩形: ", sub_rect)
						print("[LevelSelect]        - 鼠标在矩形内: ", sub_rect.has_point(mouse_pos))
						print("[LevelSelect]        - mouse_filter: ", sub_child.mouse_filter)
						print("[LevelSelect]        - visible: ", sub_child.visible)

	# 不拦截事件，让其他节点也能接收
	return

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# 记录 CoverImage 的初始坐标
	cover_origin = cover_image.position

	# 设置按钮可以拦截鼠标事件
	fancy_back_button.mouse_filter = Control.MOUSE_FILTER_STOP

	# 连接按钮的鼠标事件
	fancy_back_button.mouse_entered.connect(_on_fancy_back_button_mouse_entered)
	fancy_back_button.mouse_exited.connect(_on_fancy_back_button_mouse_exited)

	# 监听 Cell 点击事件
	BattleEventBus.cell_pressed.connect(_on_cell_pressed)
	
	# 获取 GridContainer 下的所有子节点
	var cells: Array = grid.get_children()
	print("[LevelSelect] 正在尝试连接 Cell 个数: ", board.get_child_count())
	
	# 对格子进行排序（按名称顺序）
	cells.sort_custom(func(a, b): return a.name.naturalnocasecmp_to(b.name) < 0)

	# 遍历所有 Cell，收集 Highlight 节点并连接鼠标事件
	for i in range(cells.size()):
		var cell: Control = cells[i] as Control
		if cell != null:
			print("[LevelSelect] 连接 Cell ", i, " 信号")

			# 获取 Root 节点（实际接收鼠标事件的节点）
			var root: Control = cell.get_node_or_null("Root") as Control
			if root != null:
				print("[LevelSelect] Cell ", i, " Root 节点已找到")

				# 收集 Highlight 节点
				var highlight: ColorRect = cell.get_node_or_null("Highlight") as ColorRect
				if highlight != null:
					cell_highlights.append(highlight)
					print("[LevelSelect] Cell ", i, " Highlight 已添加")
				else:
					print("[LevelSelect] Cell ", i, " 没有 Highlight 节点")

				# 连接鼠标事件信号到 Root 节点
				root.mouse_entered.connect(_on_cell_mouse_entered.bind(i))
				root.mouse_exited.connect(_on_cell_mouse_exited.bind(i))
				root.gui_input.connect(_on_cell_input.bind(i))
				print("[LevelSelect] Cell ", i, " 信号已连接到 Root")
			else:
				print("[LevelSelect] Cell ", i, " 没有 Root 节点")
	
	# 遍历这些子节点，为每个 Cell 设置 level_index 元数据
	var level_index: int = 1
	for cell in cells:
		# 添加类型检查，确保是 Cell 类型
		if cell is Cell:
			cell.set_meta("level_index", level_index)

			# 设置 LevelNumber 标签文本
			var level_number_label: Label = cell.get_node_or_null("LevelNumber") as Label
			if level_number_label != null:
				level_number_label.text = str(level_index)
				# 根据解锁状态设置可见性
				level_number_label.visible = (level_index <= max_unlocked_level)
			
			# 根据解锁状态设置 Cell 状态
			if level_index <= max_unlocked_level:
				cell.set_state(Cell.CellState.AVAILABLE)
			else:
				cell.set_state(Cell.CellState.HIDDEN)
		
		level_index += 1

# 鼠标进入按钮区域
func _on_fancy_back_button_mouse_entered() -> void:
	print("鼠标进入了！")

	# 使用 Tween 动画移动 CoverImage
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(cover_image, "position", cover_origin + Vector2(200, 0), 0.3)

# 鼠标离开按钮区域
func _on_fancy_back_button_mouse_exited() -> void:
	print("鼠标离开了！")

	# 使用 Tween 动画恢复 CoverImage 位置
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(cover_image, "position", cover_origin, 0.3)

# 处理 Cell 点击事件
func _on_cell_pressed(cell: Cell, context: Dictionary) -> void:
	# 检查是否是隐藏状态，如果是则直接返回
	if cell.state == Cell.CellState.HIDDEN:
		return
	
	# 获取关卡索引
	var level_index: int = cell.get_meta("level_index", 0)
	
	# 检查是否已解锁
	if level_index <= max_unlocked_level:
		# 已解锁，跳转到战斗场景
		BattleEventBus.go("battle", {"level_id": level_index})
	else:
		# 未解锁，打印提示
		print("请先通关上一关")

# 处理 Cell 鼠标进入事件
func _on_cell_mouse_entered(index: int) -> void:
	if index >= 0 and index < cell_highlights.size():
		cell_highlights[index].visible = true

# 处理 Cell 鼠标移出事件
func _on_cell_mouse_exited(index: int) -> void:
	if index >= 0 and index < cell_highlights.size():
		cell_highlights[index].visible = false

# 处理 Cell 输入事件
func _on_cell_input(event: InputEvent, index: int) -> void:
	print("[LevelSelect] _on_cell_input 被调用，index: ", index, " event: ", event.get_class())

	# 只处理鼠标左键按下事件
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("[LevelSelect] 点击了关卡: ", index + 1)

		# 检查是否已解锁
		if index + 1 > max_unlocked_level:
			# 未解锁，显示提示
			var message_label: Label = get_node_or_null("MessageLabel") as Label
			if message_label != null:
				message_label.text = "请先通关上一关"
				message_label.visible = true
				print("[LevelSelect] 关卡未解锁")
		else:
			# 已解锁，进入关卡
			print("[LevelSelect] 进入关卡: ", index + 1)
			BattleEventBus.go("battle", {"level_id": index + 1})


func _on_cell_00_mouse_entered() -> void:
	pass # Replace with function body.


func _on_cell_01_mouse_entered() -> void:
	pass # Replace with function body.


func _on_cell_02_mouse_entered() -> void:
	pass # Replace with function body.


func _on_cell_10_mouse_entered() -> void:
	pass # Replace with function body.


func _on_cell_11_mouse_entered() -> void:
	pass # Replace with function body.


func _on_cell_12_mouse_entered() -> void:
	pass # Replace with function body.


func _on_cell_20_mouse_entered() -> void:
	pass # Replace with function body.


func _on_cell_21_mouse_entered() -> void:
	pass # Replace with function body.


func _on_cell_22_mouse_entered() -> void:
	pass # Replace with function body.
