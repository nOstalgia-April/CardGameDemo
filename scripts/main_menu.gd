extends Control
@export var BGMIntro: AudioStream
@export var BGMLoop: AudioStream

const LEVEL_SELECT_PATH: String = "res://tscns/level_select.tscn"
const BATTLE_PATH: String = "res://tscns/battle.tscn"

@onready var start_battle_button: TextureButton = $StartBattleButton
@onready var start_battle_anim: AnimationPlayer = $StartBattleButton/AnimationPlayer
@onready var info_button: TextureButton = $InfoButton
@onready var about_info_layer: CanvasLayer = $AboutInfoLayer
@onready var info_panel: Control = $AboutInfoLayer/InfoPanel
@onready var info_panel_bg: TextureRect = $AboutInfoLayer/InfoPanel/BG
@onready var info_exit_button: TextureButton = $AboutInfoLayer/InfoPanel/ExitButton

var _level_select_scene: PackedScene = null
var _battle_scene: PackedScene = null
var _preload_requested: bool = false
var _bgm_started: bool = false
var _pass_layer: CanvasLayer = null

func _on_start_pressed() -> void:
	await _ensure_preload_ready()
	BattleEventBus.go("level_select")
	SoundManager.play_sfx("MainPlayPress")

func _ready() -> void:
	# 强制应用中文字体主题
	var default_theme = load("res://default_theme.tres")
	if default_theme != null:
		theme = default_theme

	_play_room_bgm()
	if about_info_layer != null:
		about_info_layer.visible = false
	if start_battle_button != null:
		var start_texture := start_battle_button.texture_hover if start_battle_button.texture_hover != null else start_battle_button.texture_normal
		_apply_click_mask(start_battle_button, start_texture)
		start_battle_button.mouse_entered.connect(_on_start_hovered)
		start_battle_button.mouse_exited.connect(_on_start_unhovered)
	if info_button != null:
		_apply_click_mask(info_button, info_button.texture_normal)
		info_button.pivot_offset = info_button.size * 0.5
		info_button.pressed.connect(_on_info_pressed)
		info_button.mouse_entered.connect(_on_info_hovered)
		info_button.mouse_exited.connect(_on_info_unhovered)
	if info_panel != null:
		info_panel.mouse_filter = Control.MOUSE_FILTER_PASS
		info_panel.gui_input.connect(_on_info_panel_gui_input)
	if info_exit_button != null:
		info_exit_button.pressed.connect(_on_info_exit_pressed)
	_start_preload()
	_check_game_cleared()

func _check_game_cleared() -> void:
	if GameState != null and GameState.game_cleared:
		GameState.game_cleared = false
		_show_pass_screen()

func _show_pass_screen() -> void:
	_pass_layer = CanvasLayer.new()
	_pass_layer.layer = 200 # Topmost
	add_child(_pass_layer)
	
	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.8)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_pass_layer.add_child(bg)
	
	var texture_rect = TextureRect.new()
	texture_rect.texture = load("res://assets/UI/Pass.PNG")
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_pass_layer.add_child(texture_rect)

func _input(event: InputEvent) -> void:
	if _pass_layer != null and is_instance_valid(_pass_layer):
		if (event is InputEventMouseButton and event.pressed) or (event is InputEventKey and event.pressed):
			_hide_pass_screen()
			get_viewport().set_input_as_handled()

func _hide_pass_screen() -> void:
	if _pass_layer != null and is_instance_valid(_pass_layer):
		_pass_layer.queue_free()
		_pass_layer = null

func _play_room_bgm() -> void:
	if _bgm_started:
		return
	_bgm_started = true
	if BGMIntro != null:
		SoundManager.play_bgm(BGMIntro)
		var intro_length := BGMIntro.get_length()
		if intro_length > 0.0 and BGMLoop != null:
			await get_tree().create_timer(intro_length).timeout
			SoundManager.play_bgm(BGMLoop)
			return
	if BGMLoop != null:
		SoundManager.play_bgm(BGMLoop)

func _on_start_hovered() -> void:
	if start_battle_anim != null:
		start_battle_anim.play("hover")
	SoundManager.play_sfx("MainPlaySplat")

func _on_start_unhovered() -> void:
	if start_battle_anim != null:
		start_battle_anim.play("RESET")

func _on_info_pressed() -> void:
	_set_info_visible(about_info_layer != null and !about_info_layer.visible)
	SoundManager.play_sfx("ComputerClick")

func _on_info_hovered() -> void:
	SoundManager.play_sfx("UiWoodClick")
	if info_button != null:
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(info_button, "scale", Vector2(1.1, 1.1), 0.1)

func _on_info_unhovered() -> void:
	if info_button != null:
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(info_button, "scale", Vector2(1.0, 1.0), 0.1)

func _on_info_exit_pressed() -> void:
	_set_info_visible(false)
	SoundManager.play_sfx("ComputerClick")

func _on_info_panel_gui_input(event: InputEvent) -> void:
	if about_info_layer == null or !about_info_layer.visible:
		return
	if !(event is InputEventMouseButton):
		return
	if !event.pressed or event.button_index != MOUSE_BUTTON_LEFT:
		return
	if info_exit_button != null and info_exit_button.get_global_rect().has_point(event.global_position):
		return
	if info_panel_bg != null and info_panel_bg.get_global_rect().has_point(event.global_position):
		return
	_set_info_visible(false)

func _set_info_visible(visible: bool) -> void:
	if about_info_layer != null:
		about_info_layer.visible = visible

func _start_preload() -> void:
	if _preload_requested:
		return
	_preload_requested = true
	ResourceLoader.load_threaded_request(LEVEL_SELECT_PATH)
	ResourceLoader.load_threaded_request(BATTLE_PATH)

func _ensure_preload_ready() -> void:
	_start_preload()
	var level_status := ResourceLoader.load_threaded_get_status(LEVEL_SELECT_PATH)
	var battle_status := ResourceLoader.load_threaded_get_status(BATTLE_PATH)
	while level_status == ResourceLoader.THREAD_LOAD_IN_PROGRESS or battle_status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		await get_tree().process_frame
		level_status = ResourceLoader.load_threaded_get_status(LEVEL_SELECT_PATH)
		battle_status = ResourceLoader.load_threaded_get_status(BATTLE_PATH)
	if level_status == ResourceLoader.THREAD_LOAD_LOADED:
		_level_select_scene = ResourceLoader.load_threaded_get(LEVEL_SELECT_PATH)
	if battle_status == ResourceLoader.THREAD_LOAD_LOADED:
		_battle_scene = ResourceLoader.load_threaded_get(BATTLE_PATH)

func _apply_click_mask(button: TextureButton, texture: Texture2D) -> void:
	if button == null or texture == null:
		return
	var image := texture.get_image()
	if image == null:
		return
	if image.is_compressed():
		image.decompress()
	var bitmap := BitMap.new()
	bitmap.create_from_image_alpha(image, 0.1)
	button.texture_click_mask = bitmap
