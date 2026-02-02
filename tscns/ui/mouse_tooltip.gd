extends Control
class_name MouseTooltip

var new_label : String
@onready var label: Label = $Label

func _ready() -> void:
	# Ensure high Z-index to stay on top
	z_index = 100
	# Triple the font size (assuming default is around 16, make it bigger or relative)
	# If using Theme overrides, we can set it directly.
	label.add_theme_font_size_override("font_size", 24) # 16 * 3 = 48
	set_centered_position(label.position)
	# Shake animation
	var tween = create_tween()
	var original_pos = label.position
	for i in range(10):
		var offset = 4.0 if i % 2 == 0 else -4.0
		tween.tween_property(label, "position:x", original_pos.x + offset, 0.05)
	tween.tween_property(label, "position:x", original_pos.x, 0.05)
	
	# Fade out and delete
	var fade_tween = create_tween()
	fade_tween.tween_interval(1.5)
	fade_tween.tween_property(self, "modulate:a", 0.0, 0.5)
	fade_tween.tween_callback(queue_free)

func set_text(text: String) -> void:
	new_label = text

# 新增：居中对齐鼠标位置
func set_centered_position(mouse_pos: Vector2) -> void:
	if label:
		# 获取文本的实际尺寸
		var text_size: Vector2 = label.get_minimum_size()
		# 计算居中位置（鼠标位置减去文本宽度的一半）
		global_position = mouse_pos - Vector2(text_size.x / 2, 0)
