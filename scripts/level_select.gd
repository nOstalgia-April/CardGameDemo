extends Node2D

# 引用 Board 节点
@onready var board: Control = $Root/Board

# 最大解锁关卡数
var max_unlocked_level: int = 2  # 暂时手动设为2，方便测试

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# 监听 Cell 点击事件
	BattleEventBus.cell_pressed.connect(_on_cell_pressed)
	
	# 获取 Board 下的所有 Cell 节点
	var cells: Array = board.find_children("", "Cell", true, false)
	
	# 遍历这些 Cell，为每个 Cell 绑定一个关卡索引（1到9）
	var level_index: int = 1
	for cell in cells:
		cell.set_meta("level_index", level_index)
		
		# 根据解锁状态设置 Cell 状态
		if level_index <= max_unlocked_level:
			cell.set_state(Cell.CellState.AVAILABLE)
		else:
			cell.set_state(Cell.CellState.HIDDEN)
		
		level_index += 1

# 处理 Cell 点击事件
func _on_cell_pressed(cell: Cell, context: Dictionary) -> void:
	# 获取关卡索引
	var level_index: int = cell.get_meta("level_index", 0)
	
	# 检查是否已解锁
	if level_index <= max_unlocked_level:
		# 已解锁，跳转到战斗场景
		BattleEventBus.go("battle", {"level_id": level_index})
	else:
		# 未解锁，打印提示
		print("请先通关上一关")
