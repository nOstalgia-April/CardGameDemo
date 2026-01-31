extends Control

signal return_to_level_select
signal restart_level

@onready var defeat_label = $VBoxContainer/DefeatLabel as Label

@onready var press_key_label = $VBoxContainer/PressKeyLabel
@onready var animation_player = $AnimationPlayer
@onready var victory_sound = $VictorySound

var can_input = false

func _ready():
	print(name, ": _ready started")
	# 第一步：隐藏整个 DefeatScreen（包括背景和所有子节点）
	hide()

	# 第二步：必须先把所有标签设为不可见
	defeat_label.visible = false
	press_key_label.visible = false

	# 确保动画不会自动播放
	animation_player.stop()

func open():
	# 第一步：根节点设为可见
	visible = true

	# 第二步：显示 DefeatLabel 并播放失败音乐
	defeat_label.visible = true
	victory_sound.play()

	# 设置Label的锚点到中心并调整位置
	defeat_label.set_anchors_preset(Control.PRESET_CENTER)
	defeat_label.offset_left = -defeat_label.size.x / 2
	defeat_label.offset_top = -defeat_label.size.y / 2
	defeat_label.offset_right = defeat_label.size.x / 2
	defeat_label.offset_bottom = defeat_label.size.y / 2
	
	# 设置旋转中心
	defeat_label.pivot_offset = Vector2(defeat_label.size.x / 2, defeat_label.size.y / 2)

	# 添加旋转动画
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(defeat_label, "rotation_degrees", 15, 0.5)
	tween.tween_property(defeat_label, "rotation_degrees", -15, 0.5)

	# 第三步：等待 2.0 秒
	await get_tree().create_timer(2.0).timeout

	# 第四步：隐藏 DefeatLabel
	defeat_label.visible = false

	# 第五步：显示 PressKeyLabel
	press_key_label.visible = true

	# 第六步：播放 "blink" 动画
	animation_player.play("blink")

	# 第七步：允许输入
	can_input = true





func _input(event):
	if can_input:
		if event is InputEventMouseButton or event is InputEventKey:
			# 发射重启关卡信号
			restart_level.emit()

			# 打印调试信息
			print("Restart level signal emitted")

			# 防止重复触发
			can_input = false
