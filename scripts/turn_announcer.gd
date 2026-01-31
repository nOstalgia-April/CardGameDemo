extends Control
class_name TurnAnnouncer

@onready var banner: Panel = $Banner
@onready var label: Label = $Banner/CenterContainer/Label

var _tween: Tween = null

func _ready() -> void:
	banner.modulate.a = 0
	BattleEventBus.turn_started.connect(_on_player_turn_started)
	BattleEventBus.turn_ended.connect(_on_enemy_turn_started)

func _on_enemy_turn_started(turn_index: int, _context: Dictionary) -> void:
	label.text = "敌方回合"
	play_announce_animation()

func _on_player_turn_started(turn_index: int, _context: Dictionary) -> void:
	label.text = "玩家回合\n第 %s 回合" % turn_index
	play_announce_animation()

func play_announce_animation() -> void:
	if _tween != null:
		_tween.kill()

	_tween = create_tween()
	_tween.set_parallel(false)
	_tween.tween_property(banner, "modulate:a", 1.0, 0.2)
	_tween.tween_interval(0.8)
	_tween.tween_property(banner, "modulate:a", 0.0, 0.2)
