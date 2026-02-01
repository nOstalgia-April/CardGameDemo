extends Label

@export_group("Text")
@export var format_text: String = "%d/%d"
@export var format_text_no_cap: String = "%d"
@export_group("")

const TOOLTIP_NAME: String = "行动点"
const TOOLTIP_DESC: String = "行动点，移动 / 攻击会消耗\r每回合增加一点，上限为5点"

var _hover_targets: Array[Control] = []

func _ready() -> void:
	var cb: Callable = Callable(self, "_on_resource_changed")
	BattleEventBus.connect("resource_changed", cb)
	_hover_targets = [self]
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_entered.connect(_on_hover_started.bind(self))
	mouse_exited.connect(_on_hover_ended.bind(self))
	var texture_rect: Control = get_parent().get_node_or_null("TextureRect") as Control
	if texture_rect != null:
		_hover_targets.append(texture_rect)
		texture_rect.mouse_filter = Control.MOUSE_FILTER_STOP
		texture_rect.mouse_entered.connect(_on_hover_started.bind(texture_rect))
		texture_rect.mouse_exited.connect(_on_hover_ended.bind(texture_rect))

func _on_resource_changed(energy: int, _flips_left: int, context: Dictionary) -> void:
	var cap: int = int(context.get("energy_cap", -1))
	if cap >= 0:
		text = format_text % [energy, cap]
	else:
		text = format_text_no_cap % [energy]

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
