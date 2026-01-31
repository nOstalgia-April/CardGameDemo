extends Node

@export var hint_texture: TextureRect
@export var confirm_button: Control

func _ready() -> void:
	# 连接 BattleEventBus 的信号
	BattleEventBus.unit_placed.connect(_on_unit_placed)
	BattleEventBus.turn_started.connect(_on_turn_started)

	# 初始化时默认隐藏提示
	if hint_texture != null:
		hint_texture.visible = false

func show_hint_state() -> void:
	# 显示提示图片，隐藏确认按钮
	if hint_texture != null:
		hint_texture.visible = true
	if confirm_button != null:
		confirm_button.visible = false

func show_button_state() -> void:
	# 隐藏提示图片，显示确认按钮
	if hint_texture != null:
		hint_texture.visible = false
	if confirm_button != null:
		confirm_button.visible = true

func _on_unit_placed(_unit: Node, _cell: Node, _context: Dictionary) -> void:
	# 单位放置后，显示确认按钮
	show_button_state()

func _on_turn_started(_turn_index: int, _context: Dictionary) -> void:
	# 回合开始时，显示提示图片
	show_hint_state()
