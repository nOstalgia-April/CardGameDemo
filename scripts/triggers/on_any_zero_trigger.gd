extends FlipTrigger
class_name OnAnyZeroTrigger

func _bind() -> void:
	# 监听单位数值变化事件
	if unit != null and unit.has_signal("values_changed"):
		unit.connect("values_changed", _on_values_changed)

func cleanup() -> void:
	# 清理连接的信号
	if unit != null and unit.has_signal("values_changed") and unit.is_connected("values_changed", _on_values_changed):
		unit.disconnect("values_changed", _on_values_changed)
	unit = null

func _on_values_changed(_unit: Node) -> void:
	print('翻面')
	# 检查是否有任何方向的数值变为0或负数
	if unit == null:
		return
		
	var any_zero: bool = false
	 
	# 检查四个方向的数值
	if unit.value_n <= 0 and unit.base_n > 0:
		any_zero = true
	elif unit.value_e <= 0 and unit.base_e > 0:
		any_zero = true
	elif unit.value_s <= 0 and unit.base_s > 0:
		any_zero = true
	elif unit.value_w <= 0 and unit.base_w > 0:
		any_zero = true
	
	if any_zero:
		# 触发翻转效果
		var context: Dictionary = {"trigger": "any_zero"}
		unit.flip(context)

func on_death(_context: Dictionary = {}) -> bool:
	# 死亡时不触发此效果
	return false

func on_placed(_context: Dictionary = {}) -> void:
	# 放置时不需要特殊处理
	await unit.get_tree().process_frame
