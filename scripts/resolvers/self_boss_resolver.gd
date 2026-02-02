extends UnitResolver
class_name SelfBossResolver

@export var stat_multiplier: int = 1
@export var action_count: int = 1

func resolve(unit: UnitCard) -> bool:
	if !enabled:
		await unit.get_tree().process_frame
		return false

	# --- 第1部分：移动/攻击（多次行动）---
	# 复用 AttackOrMoveResolver 的逻辑，确保行为一致
	
	print("[SelfBossResolver] Starting %d action(s)" % action_count)
	
	# 创建一个标准 resolver 实例
	var attack_or_move: AttackOrMoveResolver = AttackOrMoveResolver.new()
	# 可选：关闭它内部的 debug 日志，避免输出太多；或者保留
	attack_or_move.debug_log = true 
	
	for i in range(action_count):
		# 每一轮都需要重新评估棋盘状态
		print("[SelfBossResolver] Action %d/%d..." % [i + 1, action_count])
		
		# 委托给标准 resolver 执行
		var did_action: bool = await attack_or_move.resolve(unit)
		
		if did_action:
			print("[SelfBossResolver] Action %d completed." % (i + 1))
			# 每次行动之间稍微等一下
			await unit.get_tree().create_timer(0.3).timeout
		else:
			print("[SelfBossResolver] Action %d skipped (no valid move/attack)." % (i + 1))

	# --- 第2部分：属性提升 ---
	# 根据“其他单位数量”计算属性增量
	
	var other_units_count: int = 0
	
	# 通过 BattleEventBus 从 Board 获取单位列表
	var context: Dictionary = {
		"units": []
	}
	BattleEventBus.emit_signal("units_requested", null, context)
	var all_units: Array = context.get("units", [])
	print("[SelfBossResolver] Total units from Board: %d" % all_units.size())
	
	# 为了稳妥：遍历并排除自身
	other_units_count = 0
	for other in all_units:
		if other != unit:
			other_units_count += 1
			
	var increment: int = other_units_count * stat_multiplier
	print("[SelfBossResolver] Phase End. Other units: %d, Multiplier: %d, Increment: %d" % [other_units_count, stat_multiplier, increment])
	
	if increment > 0:
		unit.increase_stats(increment)
		print("[SelfBossResolver] Stats increased by %d" % increment)
		# 如需给视觉表现留时间，可以加一个小延迟
		await unit.get_tree().create_timer(0.3).timeout
	else:
		print("[SelfBossResolver] No stat increase (increment <= 0)")

	return true
