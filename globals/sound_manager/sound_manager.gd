# res://globals/sound_manager.gd
extends Node

@onready var sfx: Node = $SFX
@onready var bgm_player: AudioStreamPlayer = $BGMPlayer

signal ready_for_use

var _loop_sfx_states: Dictionary = {}

func _ready() -> void:
	emit_signal("ready_for_use")
	
func play_sfx(name: String) -> AudioStreamPlayer:
	var player := sfx.get_node(name) as AudioStreamPlayer
	if not player:
		print('未找到音效文件 %s' % name)
		return
	player.play()
	return player
	
func play_bgm(strem: AudioStream) -> void:
	print("play_bgm")
	if bgm_player.stream == strem and bgm_player.playing:
		return
	bgm_player.stream = strem
	bgm_player.play()

func request_loop_sfx(name: String, requester: String, active: bool, fade_in_seconds: float = 0.15, fade_out_seconds: float = 0.2, muted_volume_db: float = -80.0) -> void:
	var player := sfx.get_node_or_null(name) as AudioStreamPlayer
	if player == null:
		print('未找到音效文件 %s' % name)
		return
	if not active and not _loop_sfx_states.has(name) and not player.playing:
		return

	var state: Dictionary
	if not _loop_sfx_states.has(name):
		state = {
			"requesters": {},
			"tween": null,
			"initial_volume_db": player.volume_db,
		}
		_loop_sfx_states[name] = state
	else:
		state = _loop_sfx_states[name] as Dictionary

	var requesters := state.get("requesters", {}) as Dictionary
	if active:
		requesters[requester] = true
	else:
		requesters.erase(requester)
	state["requesters"] = requesters

	var tween := state.get("tween") as Tween
	if tween != null:
		tween.kill()
		tween = null

	var initial_volume_db := float(state.get("initial_volume_db", player.volume_db))
	var should_play := requesters.size() > 0

	if should_play:
		if not player.playing:
			player.volume_db = muted_volume_db
			player.stream_paused = false
			player.play()

		if fade_in_seconds <= 0.0:
			player.volume_db = initial_volume_db
		else:
			tween = create_tween()
			tween.tween_property(player, "volume_db", initial_volume_db, fade_in_seconds)
	else:
		if not player.playing:
			player.volume_db = initial_volume_db
		elif fade_out_seconds <= 0.0:
			player.stop()
			player.volume_db = initial_volume_db
		else:
			tween = create_tween()
			tween.tween_property(player, "volume_db", muted_volume_db, fade_out_seconds)
			tween.tween_callback(func() -> void:
				player.stop()
				player.volume_db = initial_volume_db
			)

	state["tween"] = tween
	_loop_sfx_states[name] = state

func setup_ui_sounds(node: Node) -> void:
	var button := node as BaseButton
	if button:
		#button.pressed.connect(SoundManager.play_sfx.bind('WindowClick'))
		#button.mouse_entered.connect(SoundManager.play_sfx.bind('WindowFocus'))
		pass
	
	for child in node.get_children():
		setup_ui_sounds(child)

func stop_all_sfx() -> void:
	for name in _loop_sfx_states.keys():
		var state := _loop_sfx_states[name] as Dictionary
		var tween := state.get("tween") as Tween
		if tween != null:
			tween.kill()

		var player := sfx.get_node_or_null(str(name)) as AudioStreamPlayer
		if player != null and state.has("initial_volume_db"):
			player.volume_db = float(state["initial_volume_db"])

	_loop_sfx_states.clear()

	for s in sfx.get_children() as Array[AudioStreamPlayer]:
		s.stop()
