extends Control
class_name TooltipManager

@onready var tooltip_panel: Panel = $TooltipPanel
@onready var name_label: Label = $TooltipPanel/VBoxContainer/NameLabel
@onready var desc_label: Label = $TooltipPanel/VBoxContainer/DescLabel

func _ready() -> void:
	_setup_styles()

	if tooltip_panel != null:
		tooltip_panel.visible = false

	BattleEventBus.connect("unit_hover_started", _on_unit_hover_started)
	BattleEventBus.connect("unit_hover_ended", _on_unit_hover_ended)

func _setup_styles() -> void:
	# 设置 Panel 样式
	if tooltip_panel != null:
		var panel_style: StyleBoxFlat = StyleBoxFlat.new()
		panel_style.bg_color = Color(0.1, 0.1, 0.18, 0.95)  # 深蓝黑半透明
		panel_style.border_width_left = 2
		panel_style.border_width_top = 2
		panel_style.border_width_right = 2
		panel_style.border_width_bottom = 2
		panel_style.border_color = Color(1.0, 0.843, 0.0, 1.0)  # 金色边框
		panel_style.corner_radius_top_left = 5
		panel_style.corner_radius_top_right = 5
		panel_style.corner_radius_bottom_left = 5
		panel_style.corner_radius_bottom_right = 5
		panel_style.content_margin_left = 15
		panel_style.content_margin_top = 15
		panel_style.content_margin_right = 15
		panel_style.content_margin_bottom = 15
		panel_style.shadow_color = Color(0, 0, 0, 0.5)
		panel_style.shadow_size = 5
		panel_style.shadow_offset = Vector2(2, 2)
		tooltip_panel.add_theme_stylebox_override("panel", panel_style)

	# 设置 NameLabel 样式
	if name_label != null:
		var name_settings: LabelSettings = LabelSettings.new()
		name_settings.font_size = 22
		name_settings.font_color = Color(1.0, 0.843, 0.0, 1.0)  # 金色
		name_label.label_settings = name_settings
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	# 设置 DescLabel 样式
	if desc_label != null:
		var desc_settings: LabelSettings = LabelSettings.new()
		desc_settings.font_size = 15
		desc_settings.font_color = Color(0.875, 0.875, 0.875, 1.0)  # 米白色
		desc_settings.line_spacing = 4
		desc_label.label_settings = desc_settings
		desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		desc_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

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
