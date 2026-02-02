extends Control

signal return_to_level_select

@onready var victory_label = $VBoxContainer/VictoryLabel as Label
@onready var info_label = $VBoxContainer/InfoLabel
@onready var press_key_label = $VBoxContainer/PressKeyLabel
@onready var animation_player = $AnimationPlayer
@onready var victory_sound = $VictorySound

var can_input = false

func _ready():
	# 第一步：隐藏整个 VictoryScreen（包括背景和所有子节点）
	hide()

	# 第二步：必须先把所有标签设为不可见
	victory_label.visible = false
	info_label.visible = false
	press_key_label.visible = false

	# 确保动画不会自动播放
	animation_player.stop()

func open():
	# 第一步：根节点设为可见
	visible = true

	# 第二步：显示 VictoryLabel 并播放胜利音乐
	victory_label.visible = true
	victory_sound.play()

	# 设置Label的锚点到中心并调整位置
	victory_label.set_anchors_preset(Control.PRESET_CENTER)
	victory_label.offset_left = -victory_label.size.x / 2
	victory_label.offset_top = -victory_label.size.y / 2
	victory_label.offset_right = victory_label.size.x / 2
	victory_label.offset_bottom = victory_label.size.y / 2
	
	# 设置旋转中心
	victory_label.pivot_offset = Vector2(victory_label.size.x / 2, victory_label.size.y / 2)

	# 添加旋转动画
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(victory_label, "rotation_degrees", 15, 0.3)
	tween.tween_property(victory_label, "rotation_degrees", -15, 0.3)

	# 第三步：等待 1.2 秒
	await get_tree().create_timer(1.2).timeout

	# 第四步：隐藏 VictoryLabel
	victory_label.visible = false

	# 第五步：显示 InfoLabel 和 PressKeyLabel
	info_label.visible = true
	press_key_label.visible = true

	# 第六步：播放 "blink" 动画
	animation_player.play("blink")

	# 第七步：允许输入
	can_input = true





func _input(event):
	if can_input:
		if event is InputEventMouseButton or event is InputEventKey:
			# 发射返回信号
			return_to_level_select.emit()

			# 打印调试信息
			print("Return signal emitted")

			# 防止重复触发
			can_input = false
