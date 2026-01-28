extends Control

# 测试撞击动画的脚本
# 这个文件用于测试动画是否正常工作

func _ready() -> void:
	# 等待一秒后播放动画
	await get_tree().create_timer(1.0).timeout
	play_bump_animation(1)  # 向东方向

func play_bump_animation(direction: int) -> void:
	print("开始播放撞击动画，方向：", direction)

	var bump_distance: float = 30.0
	var bump_duration_forward: float = 0.1
	var bump_duration_backward: float = 0.15

	# 根据方向计算移动向量
	var bump_vector: Vector2 = Vector2.ZERO

	match direction:
		0:  # N
			bump_vector = Vector2(0, -bump_distance)
		1:  # E
			bump_vector = Vector2(bump_distance, 0)
		2:  # S
			bump_vector = Vector2(0, bump_distance)
		3:  # W
			bump_vector = Vector2(-bump_distance, 0)

	print("撞击向量：", bump_vector)
	print("原始位置：", position)

	# 创建 Tween
	var tween: Tween = create_tween()
	if tween == null:
		print("错误：无法创建 Tween")
		return

	# 保存原始位置
	var original_position: Vector2 = position

	# 动画序列：向前冲锋 -> 弹回
	tween.tween_property(self, "position", original_position + bump_vector, bump_duration_forward).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(self, "position", original_position, bump_duration_backward).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)

	print("动画已设置")
