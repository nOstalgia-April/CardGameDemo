extends Camera2D

# 震动强度
var shake_intensity := 0.0
# 震动持续时间（秒）
var shake_duration := 0.0
# 是否正在震动
var is_shaking := false

# 随机数生成器
var rng := RandomNumberGenerator.new()

# 保存原始偏移
var base_offset := Vector2.ZERO

func _ready() -> void:
	# 启用处理
	set_process(true)
	rng.randomize()
	# 保存原始偏移
	base_offset = offset
	# 默认禁用摄像机，只在震动时启用
	enabled = false

func _process(delta: float) -> void:
	if is_shaking:
		shake_duration -= delta
		if shake_duration <= 0:
			is_shaking = false
			offset = base_offset
			# 震动结束后禁用摄像机
			enabled = false
		else:
			# 使用随机偏移实现震动，基于原始偏移
			offset = base_offset + Vector2(
				rng.randf_range(-shake_intensity, shake_intensity),
				rng.randf_range(-shake_intensity, shake_intensity)
			)

# 开始震动
# intensity: 震动强度（像素）
# duration: 震动持续时间（秒）
func shake(intensity: float, duration: float) -> void:
	shake_intensity = intensity
	shake_duration = duration
	is_shaking = true
	# 震动时启用摄像机
	enabled = true
