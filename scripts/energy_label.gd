extends Label

@export_group("Text")
@export var format_text: String = "%d"
@export var format_text_no_cap: String = "%d"
@export_group("")

const TOOLTIP_NAME: String = "行动点"
const TOOLTIP_DESC: String = "行动点，移动 / 攻击 / 放置棋子 会消耗\r每回合增加一点，上限为5点"

# Assets
const Light0 = preload("res://assets/UI/BattleHUD/Light0.png")
const Light1 = preload("res://assets/UI/BattleHUD/Light1.png")
const Light2 = preload("res://assets/UI/BattleHUD/Light2.png")
const Light3 = preload("res://assets/UI/BattleHUD/Light3.png")
const Light_Closed = preload("res://assets/UI/BattleHUD/Lihgt_closed.png")

const ANIM_FRAMES = [Light0, Light1, Light2, Light3]

var _hover_targets: Array[Control] = []
var _previous_energy: int = -1
var _anim_tween: Tween = null
var _texture_rect: TextureRect = null

func _ready() -> void:
	var cb: Callable = Callable(self, "_on_resource_changed")
	BattleEventBus.connect("resource_changed", cb)
	_hover_targets = [self]
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_entered.connect(_on_hover_started.bind(self))
	mouse_exited.connect(_on_hover_ended.bind(self))
	var texture_rect: Control = get_parent().get_node_or_null("TextureRect") as Control
	if texture_rect != null:
		_texture_rect = texture_rect as TextureRect
		_texture_rect.texture = Light0
		_hover_targets.append(texture_rect)
		texture_rect.mouse_filter = Control.MOUSE_FILTER_STOP
		texture_rect.mouse_entered.connect(_on_hover_started.bind(texture_rect))
		texture_rect.mouse_exited.connect(_on_hover_ended.bind(texture_rect))

func _on_resource_changed(energy: int, _flips_left: int, context: Dictionary) -> void:
	var cap: int = int(context.get("energy_cap", -1))
	if cap >= 0:
		text = format_text % [energy]
	else:
		text = format_text_no_cap % [energy]
	
	if _previous_energy != -1 and energy < _previous_energy:
		_play_use_anim()
	
	if energy == 0:
		# If we just hit 0, playing sound
		if _previous_energy > 0:
			SoundManager.play_sfx("UiLowPower")
		# We set texture to closed, but if animation is playing, we might want to wait?
		# User said "play animation when used".
		# If energy becomes 0, it is "used".
		# But also "set to closed when 0".
		# If I set to closed immediately, animation is overridden.
		# I'll let the animation finish then set to closed if energy is still 0.
		#if _anim_tween == null or !_anim_tween.is_valid():
			if _texture_rect: _texture_rect.texture = Light_Closed
	elif _texture_rect and _texture_rect.texture == Light_Closed:
		_texture_rect.texture = Light0
		
	_previous_energy = energy

func _play_use_anim() -> void:
	if _texture_rect == null: return
	if _anim_tween: _anim_tween.kill()
	
	_anim_tween = create_tween()
	var frame_duration = 2.0 / float(ANIM_FRAMES.size())
	for frame in ANIM_FRAMES:
		_anim_tween.tween_callback(func(): _texture_rect.texture = frame)
		_anim_tween.tween_interval(frame_duration)
	
	_anim_tween.tween_callback(func():
		if _previous_energy == 0:
			_texture_rect.texture = Light_Closed
		else:
			_texture_rect.texture = Light0
	)

func _on_hover_started(source: Control) -> void:
	if source == null:
		return
	BattleEventBus.emit_signal("unit_hover_started", {
		"global_rect": source.get_global_rect(),
		"name": TOOLTIP_NAME,
		"desc": TOOLTIP_DESC,
	})

func _on_hover_ended(_source: Control) -> void:
	var mouse_pos: Vector2 = get_global_mouse_position()
	for target in _hover_targets:
		if target != null and target.get_global_rect().has_point(mouse_pos):
			return
	BattleEventBus.emit_signal("unit_hover_ended")
