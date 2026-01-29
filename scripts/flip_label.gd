extends Label

@export_group("Text")
@export var format_text: String = "翻牌：%d"
@export_group("")

func _ready() -> void:
	var cb: Callable = Callable(self, "_on_resource_changed")
	BattleEventBus.connect("resource_changed", cb)

func _on_resource_changed(_energy: int, flips_left: int, _context: Dictionary) -> void:
	text = format_text % [flips_left]
