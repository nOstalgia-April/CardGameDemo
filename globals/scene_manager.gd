extends Node

const SCENES := {
	"main": "res://main.tscn",
	"battle": "res://tscns/battle.tscn",
	"level_select": "res://tscns/level_select.tscn",
}

var _is_changing := false

func _ready() -> void:
	BattleEventBus.request_scene.connect(_on_request_scene)

func _on_request_scene(scene_key: String, payload: Dictionary) -> void:
	if _is_changing:
		return
	var path := str(SCENES.get(scene_key, ""))
	if path == "":
		push_error("Unknown scene_key: %s" % scene_key)
		return
	_is_changing = true
	if SoundManager:
		SoundManager.stop_all_sfx()
	if Transition:
		if Transition.has_method("prepare"):
			Transition.prepare(scene_key)
		await Transition.fade_out()

	get_tree().call_deferred("change_scene_to_file", path)
	await get_tree().process_frame
	await get_tree().process_frame
	if Transition:
		await Transition.fade_in()
	_is_changing = false
