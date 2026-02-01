extends TextureRect

@export_group("Text")
@export var format_text: String = "翻牌：%d"
@export_group("Texture")
@export var CanUse: Texture2D
@export var CannotUse: Texture2D

const TOOLTIP_NAME: String = "翻牌"
const TOOLTIP_DESC: String = "右键卡牌可以翻牌消耗\r每回合仅限一次"

func _ready() -> void:
	BattleEventBus.resource_changed.connect(_on_resource_changed)
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_entered.connect(_on_hover_started)
	mouse_exited.connect(_on_hover_ended)

func _on_resource_changed(_energy: int, flips_left: int, _context: Dictionary) -> void:
	if flips_left == 1:
		texture = CanUse
	else:
		texture = CannotUse

func _on_hover_started() -> void:
	BattleEventBus.emit_signal("unit_hover_started", {
		"global_rect": get_global_rect(),
		"name": TOOLTIP_NAME,
		"desc": TOOLTIP_DESC,
	})

func _on_hover_ended() -> void:
	BattleEventBus.emit_signal("unit_hover_ended")
