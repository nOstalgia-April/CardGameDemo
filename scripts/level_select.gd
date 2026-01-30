extends Node2D

# 引用 Board 节点
@onready var board: Board = $Root/Board
@onready var grid: GridContainer = $Root/Board/GridContainer

# 引用 FancyBackButton 和 CoverImage
@onready var fancy_back_button: TextureButton = $CanvasLayer/BackAnchor/FancyBackButton
@onready var cover_image: TextureRect = $CanvasLayer/BackAnchor/FancyBackButton/CoverImage

# 最大解锁关卡数
var max_unlocked_level: int = 2  # 暂时手动设为2，方便测试

# CoverImage 的初始坐标
var cover_origin: Vector2

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
	
	# 对格子进行排序（按名称顺序）
	cells.sort_custom(func(a, b): return a.name.naturalnocasecmp_to(b.name) < 0)
	
	# 遍历这些子节点，为每个 Cell 设置 level_index 元数据
	var level_index: int = 1
	for cell in cells:
		# 添加类型检查，确保是 Cell 类型
		if cell is Cell:
			cell.set_meta("level_index", level_index)
			
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
