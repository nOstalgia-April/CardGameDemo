extends Control
@export var BGM: AudioStream

func _on_start_pressed() -> void:
	BattleEventBus.go("level_select")

func _ready() -> void:
	SoundManager.play_bgm(BGM)
