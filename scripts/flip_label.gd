extends TextureRect

@export_group("Text")
@export var format_text: String = "翻牌：%d"
@export_group("Texture")
@export var CanUse: Texture2D
@export var CannotUse: Texture2D

const TOOLTIP_NAME: String = "翻牌"
const TOOLTIP_DESC: String = "右键卡牌可以翻牌消耗\r每回合仅限一次"

# Assets
const Eye0 = preload("res://assets/UI/BattleHUD/Eye0.png")
const Eye1 = preload("res://assets/UI/BattleHUD/Eye1.png")
const Eye2 = preload("res://assets/UI/BattleHUD/Eye2.png")
const Eye3 = preload("res://assets/UI/BattleHUD/Eye3.png")
const Eye4 = preload("res://assets/UI/BattleHUD/Eye4.png")
const Eye5_Closed = preload("res://assets/UI/BattleHUD/Eye5_closed.png")
const Eye6 = preload("res://assets/UI/BattleHUD/Eye6.png")
const Eye7 = preload("res://assets/UI/BattleHUD/Eye7.png")

const ANIM_FRAMES = [Eye0, Eye1, Eye2, Eye3, Eye4, Eye6, Eye7]

var _anim_tween: Tween = null
var _is_used: bool = false

func _ready() -> void:
	BattleEventBus.resource_changed.connect(_on_resource_changed)
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_entered.connect(_on_hover_started)
	mouse_exited.connect(_on_hover_ended)
	_start_idle_anim()

func _on_resource_changed(_energy: int, flips_left: int, _context: Dictionary) -> void:
	if flips_left == 1:
		_is_used = false
		if _anim_tween == null or !_anim_tween.is_valid():
			_start_idle_anim()
	else:
		_is_used = true
		if _anim_tween:
			_anim_tween.kill()
		texture = Eye5_Closed

func _start_idle_anim() -> void:
	if _is_used:
		return
	if _anim_tween:
		_anim_tween.kill()
	
	texture = Eye0
	_anim_tween = create_tween().set_loops()
	_anim_tween.tween_interval(3.0) # 3s open/idle
	
	# 1s animation
	var frame_duration = 1.0 / float(ANIM_FRAMES.size())
	for frame in ANIM_FRAMES:
		_anim_tween.tween_callback(func(): texture = frame)
		_anim_tween.tween_interval(frame_duration)
	_anim_tween.tween_callback(func(): texture = Eye0)

func _on_hover_started() -> void:
	BattleEventBus.emit_signal("unit_hover_started", {
		"global_rect": get_global_rect(),
		"name": TOOLTIP_NAME,
		"desc": TOOLTIP_DESC,
	})

func _on_hover_ended() -> void:
	BattleEventBus.emit_signal("unit_hover_ended")
