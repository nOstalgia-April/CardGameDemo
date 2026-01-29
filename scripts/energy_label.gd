extends Label

@export_group("Text")
@export var format_text: String = "%d/%d"
@export var format_text_no_cap: String = "%d"
@export_group("")

func _ready() -> void:
	var cb: Callable = Callable(self, "_on_resource_changed")
	BattleEventBus.connect("resource_changed", cb)

func _on_resource_changed(energy: int, _flips_left: int, context: Dictionary) -> void:
	var cap: int = int(context.get("energy_cap", -1))
	if cap >= 0:
		text = format_text % [energy, cap]
	else:
		text = format_text_no_cap % [energy]
