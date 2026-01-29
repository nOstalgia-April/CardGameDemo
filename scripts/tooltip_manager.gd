extends Control
class_name TooltipManager

@onready var tooltip_panel: Panel = $TooltipPanel
@onready var tooltip_label: Label = $TooltipPanel/TooltipLabel

func _ready() -> void:
	if tooltip_panel != null:
		tooltip_panel.visible = false

	BattleEventBus.connect("unit_hover_started", _on_unit_hover_started)
	BattleEventBus.connect("unit_hover_ended", _on_unit_hover_ended)

func _on_unit_hover_started(context: Dictionary) -> void:
	if tooltip_panel == null:
		return

	if tooltip_label != null:
		tooltip_label.text = context.get("text", "")

	var global_rect: Rect2 = context.get("global_rect", Rect2())
	global_position = global_rect.position
	tooltip_panel.visible = true

func _on_unit_hover_ended() -> void:
	if tooltip_panel != null:
		tooltip_panel.visible = false
