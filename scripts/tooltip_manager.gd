extends Control
class_name TooltipManager

@onready var tooltip_panel: Panel = $TooltipPanel
@onready var name_label: Label = $TooltipPanel/VBoxContainer/NameLabel
@onready var desc_label: Label = $TooltipPanel/VBoxContainer/DescLabel

func _ready() -> void:
	if tooltip_panel != null:
		tooltip_panel.visible = false

	BattleEventBus.connect("unit_hover_started", _on_unit_hover_started)
	BattleEventBus.connect("unit_hover_ended", _on_unit_hover_ended)

func _on_unit_hover_started(context: Dictionary) -> void:
	if tooltip_panel == null:
		return

	if name_label != null:
		name_label.text = context.get("name", "")

	if desc_label != null:
		desc_label.text = context.get("desc", "")

	var global_rect: Rect2 = context.get("global_rect", Rect2())
	global_position = global_rect.position
	tooltip_panel.visible = true

func _on_unit_hover_ended() -> void:
	if tooltip_panel != null:
		tooltip_panel.visible = false
