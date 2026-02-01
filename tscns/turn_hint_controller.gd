extends Node

@export var hint_label: TextureRect
@export var confirm_button: Control

func _ready() -> void:
	# 连接 BattleEventBus 的信号
	BattleEventBus.unit_placed.connect(_on_unit_placed)
	BattleEventBus.turn_started.connect(_on_turn_started)

func show_hint_state() -> void:
	# 显示提示文本，隐藏确认按钮
	if hint_label != null:
		hint_label.visible = true
	if confirm_button != null:
		confirm_button.hide_button()

func show_button_state() -> void:
	# 隐藏提示文本，显示确认按钮
	hint_label.visible = false
	confirm_button.show_button()

func _on_unit_placed(_unit: Node, _cell: Node, _context: Dictionary) -> void:
	# 单位放置后，显示确认按钮
	show_button_state()

func _on_turn_started(turn_index: int, _context: Dictionary) -> void:
	# 只在第一回合显示提示
	if turn_index == 1:
		show_hint_state()
