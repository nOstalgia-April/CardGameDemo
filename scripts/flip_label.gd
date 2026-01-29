extends TextureRect

@export_group("Text")
@export var format_text: String = "翻牌：%d"
@export_group("Texture")
@export var CanUse: Texture2D
@export var CannotUse: Texture2D

func _ready() -> void:
	BattleEventBus.resource_changed.connect(_on_resource_changed)

func _on_resource_changed(_energy: int, flips_left: int, _context: Dictionary) -> void:
	if flips_left == 1:
		texture = CanUse
	else:
		texture = CannotUse
