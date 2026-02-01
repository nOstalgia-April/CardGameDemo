extends Control
class_name LevelSelectCell

signal pressed(cell: LevelSelectCell)

@export var base_texture_even: Texture2D = preload("res://assets/Board/DefaultCell.png")
@export var base_texture_odd: Texture2D = preload("res://assets/Board/DefaultCell2.png")
@export var green_texture: Texture2D = preload("res://assets/Board/GreenCell.png")
@export var red_texture: Texture2D = preload("res://assets/Board/RedCell.png")
@export var super_red_texture: Texture2D = preload("res://assets/Board/SuperRedCell.jpg")

@export var hover_texture: Texture2D = preload("res://assets/Board/WhiteHover.png")
@export var select_texture: Texture2D = preload("res://assets/Board/RedHover.png")

@export var number_textures: Array[Texture2D] = [
	preload("res://assets/Number/ui_1.png"),
	preload("res://assets/Number/ui_2.png"),
	preload("res://assets/Number/ui_3.png"),
	preload("res://assets/Number/ui_4.png"),
	preload("res://assets/Number/ui_5.png"),
	preload("res://assets/Number/ui_6.png"),
	preload("res://assets/Number/ui_7.png"),
	preload("res://assets/Number/ui_8.png"),
	preload("res://assets/Number/ui_9.png")
]

@onready var base_rect: TextureRect = $Base
@onready var overlay_rect: TextureRect = $Overlay
@onready var level_label: Label = $LevelLabel

var fog_layer: ColorRect = null
var level_number_root: Control = null
var level_number_rect: TextureRect = null
var level_index: int = 0
var _locked: bool = true
var _selected: bool = false

func _ready() -> void:
	if level_number_root == null:
		# 创建一个容器用于居中定位
		level_number_root = Control.new()
		level_number_root.name = "LevelNumberRoot"
		level_number_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
		level_number_root.layout_mode = 1 # Anchors
		level_number_root.set_anchors_preset(Control.PRESET_CENTER)
		# 将缩放应用在父节点上
		level_number_root.scale = Vector2(0.25, 0.25)
		add_child(level_number_root)
		# 确保在 FogLayer 之下（如果有），Overlay 之下
		move_child(level_number_root, 2)
		
		# 创建图片节点
		level_number_rect = TextureRect.new()
		level_number_rect.name = "LevelNumberRect"
		level_number_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		# 让 TextureRect 自动在父节点中心展开
		level_number_rect.layout_mode = 1 # Anchors
		level_number_rect.set_anchors_preset(Control.PRESET_CENTER)
		level_number_rect.grow_horizontal = Control.GROW_DIRECTION_BOTH
		level_number_rect.grow_vertical = Control.GROW_DIRECTION_BOTH
		# 这里的 scale 保持为 1，因为父节点已经缩放了
		level_number_rect.scale = Vector2.ONE
		level_number_root.add_child(level_number_rect)

func setup(index: int, is_even: bool, unlocked: bool, style: String = "default") -> void:
	print("[LevelSelectCell] setup: index=", index, " unlocked=", unlocked, " style=", style)
	level_index = index
	_locked = !unlocked
	_selected = false
	
	if fog_layer == null:
		fog_layer = ColorRect.new()
		fog_layer.name = "FogLayer"
		fog_layer.color = Color(0, 0, 0, 0.6) # 战争迷雾颜色
		fog_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fog_layer.layout_mode = 1 # Anchors
		fog_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
		add_child(fog_layer)
		# 确保在 Base 之上，但在 Label 之下 (Label 是 z-index 或者顺序靠后)
		# tscn结构: Base, Overlay, LevelLabel
		# add_child 默认在最后。
		# 我们可以把它移动到 Overlay 之后
		move_child(fog_layer, 3) # Fog should cover everything except maybe selection overlay? usually fog covers base.
	
	fog_layer.visible = _locked
	
	match style:
		"green":
			base_rect.texture = green_texture
			print("[LevelSelectCell] Set texture to GREEN: ", green_texture)
		"red":
			base_rect.texture = red_texture
			print("[LevelSelectCell] Set texture to RED: ", red_texture)
		"super_red":
			base_rect.texture = super_red_texture
			print("[LevelSelectCell] Set texture to SUPER RED: ", super_red_texture)
		_:
			base_rect.texture = base_texture_even if is_even else base_texture_odd
			print("[LevelSelectCell] Set texture to DEFAULT: ", base_rect.texture)
			
	# 设置数字显示
	if unlocked and index >= 1 and index <= number_textures.size():
		# 使用图片数字
		level_label.visible = false
		if level_number_rect != null and level_number_root != null:
			level_number_rect.texture = number_textures[index - 1]
			level_number_root.visible = true
			# 无需手动调整 position，锚点系统会自动居中
			# level_number_rect.position = ... (由 PRESET_CENTER 处理)
	else:
		# 回退到文本数字（锁定状态或者超出图片范围）
		level_label.text = str(index)
		level_label.visible = unlocked
		if level_number_root != null:
			level_number_root.visible = false
			
	overlay_rect.visible = false
	# modulate = Color(1, 1, 1, 0.45) if _locked else Color(1, 1, 1, 1) # Removed modulate change

func set_selected(active: bool) -> void:
	_selected = active
	if _selected:
		overlay_rect.texture = select_texture
		overlay_rect.visible = true
	else:
		overlay_rect.visible = false

func _on_mouse_entered() -> void:
	if _locked or _selected:
		return
	overlay_rect.texture = hover_texture
	overlay_rect.visible = true
	SoundManager.play_sfx("UiBlockPassby")

func _on_mouse_exited() -> void:
	if _selected:
		return
	overlay_rect.visible = false

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		emit_signal("pressed", self)
