extends Node2D

@onready var hand_view: HandView = %HandView
@onready var board: Board = %Board
@onready var turn_manager: TurnManager = %TurnManager
@onready var root: Control = %Root
@onready var victory_screen: Control = null
@onready var victory_canvas_layer: CanvasLayer = null

@export_group("Data")
@export var card_infos_path: String = "res://Data/cards"
@export var enemy_infos_path: String = "res://Data/enemies"
@export var level_index: int = 1
@export var enemy_unit_scene: PackedScene
@export_group("")

@export_group("ScreenShake")
@export var shake_intensity_default: float = 12.0
@export var shake_duration_default: float = 0.15
@export_group("")
@export var battle_intro: AudioStream
@export var battle_loop_player_path: NodePath

const CardDataRepoScript = preload("res://scripts/data/card_data_repo.gd")
const EnemyDataRepoScript = preload("res://scripts/data/enemy_data_repo.gd")
const LevelLoaderScript = preload("res://scripts/data/level_loader.gd")

var card_repo
var enemy_repo
var enemy_infos: Dictionary = {}
var shake_intensity: float = 0.0
var shake_duration: float = 0.0
var shake_time_left: float = 0.0
var is_shaking: bool = false
var base_position: Vector2 = Vector2.ZERO
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _battle_over: bool = false
var _current_level: LevelData = null

func _ready() -> void:
	_rng.randomize()
	_sync_root_layout()
	BattleEventBus.connect("screen_shake_requested", Callable(self, "_on_screen_shake_requested"))
	BattleEventBus.connect("turn_started", Callable(self, "_on_turn_started"))
	BattleEventBus.connect("unit_placed", Callable(self, "_on_unit_placed"))
	BattleEventBus.connect("unit_died", Callable(self, "_on_unit_died"))
	if GameState != null and GameState.current_level_index > 0:
		level_index = GameState.current_level_index
	_init_repos()
	enemy_infos = enemy_repo.get_all()
	_load_and_spawn_level()
	_populate_hand_for_level()
	_play_battle_audio()
	if turn_manager != null:
		turn_manager.start_turn()
	
	# 创建CanvasLayer并加载victory_screen
	_create_victory_canvas_layer()

func _play_battle_audio() -> void:
	SoundManager.play_sfx("LevelStart")
	if battle_intro != null:
		SoundManager.play_bgm(battle_intro)
		var intro_length: float = battle_intro.get_length()
		if intro_length > 0.0:
			await get_tree().create_timer(intro_length).timeout
	var loop_player := get_node_or_null(battle_loop_player_path) as AudioStreamPlayer
	if loop_player != null:
		loop_player.play()

func _create_victory_canvas_layer() -> void:
	# 创建CanvasLayer用于胜利界面
	victory_canvas_layer = CanvasLayer.new()
	victory_canvas_layer.layer = 100  # 设置较高的层级确保在最上层
	root.add_child(victory_canvas_layer)
	
	# 加载并添加victory_screen到CanvasLayer中
	var victory_scene := preload("res://victory_screen.tscn")
	victory_screen = victory_scene.instantiate()
	victory_canvas_layer.add_child(victory_screen)
	victory_screen.hide()
	# 连接返回信号
	if victory_screen.has_signal("return_to_level_select"):
		victory_screen.connect("return_to_level_select", _on_victory_return)

func _on_victory_return() -> void:
	# 返回关卡选择界面
	BattleEventBus.go("level_select")

func _process(delta: float) -> void:
	if !is_shaking:
		return
	if base_position == Vector2.ZERO:
		base_position = root.position
	shake_time_left -= delta
	if shake_time_left <= 0.0:
		is_shaking = false
		root.position = base_position
		return
	var offset: Vector2 = Vector2(
		_rng.randf_range(-1.0, 1.0),
		_rng.randf_range(-1.0, 1.0)
	) * shake_intensity
	root.position = base_position + offset

func _on_screen_shake_requested(intensity: float, duration: float, _context: Dictionary) -> void:
	trigger_screen_shake(intensity, duration)

func _on_turn_started(turn_index: int, _context: Dictionary) -> void:
	if _battle_over:
		return
	if turn_index <= 1:
		return
	if board.find_units("player").is_empty():
		_handle_defeated()

func _on_unit_placed(_unit: Node, _cell: Node, _context: Dictionary) -> void:
	if turn_manager.turn_index == 1:
		call_deferred("_end_first_turn_later")

func _end_first_turn_later() -> void:
	turn_manager.end_turn()

func _on_unit_died(_unit: Node, _killer: Node, _dir: int, _context: Dictionary) -> void:
	if _battle_over:
		return
	call_deferred("_check_victory")

func _check_victory() -> void:
	if _battle_over:
		return
	if board.find_units("enemy").is_empty():
		_handle_victory()

func _handle_victory() -> void:
	_battle_over = true
	if GameState != null:
		GameState.unlock_next_level(level_index)
	SoundManager.play_sfx("Victory")
	# 显示胜利界面
	if victory_screen != null:
		victory_screen.call("open")
	else:
		# 如果没有victory_screen，直接切换场景
		BattleEventBus.go("level_select")

func _handle_defeated() -> void:
	_battle_over = true
	SoundManager.play_sfx("Defeated")
	BattleEventBus.emit_signal("battle_defeated", {})

func restart_level() -> void:
	GameState.set_current_level(level_index)
	BattleEventBus.go("battle")

func _sync_root_layout() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	root.position = Vector2.ZERO
	root.size = viewport_size

# 触发屏幕震动
# intensity: 震动强度（像素），如果为 0 则使用默认值
# duration: 震动持续时间（秒），如果为 0 则使用默认值
func trigger_screen_shake(intensity: float = 0.0, duration: float = 0.0) -> void:
	# 如果传入的值为 0，使用默认值
	if intensity == 0.0:
		intensity = shake_intensity_default
	if duration == 0.0:
		duration = shake_duration_default

	shake_intensity = intensity
	shake_duration = duration
	shake_time_left = duration
	is_shaking = true
	if base_position == Vector2.ZERO:
		base_position = root.position

func _init_repos() -> void:
	card_repo = CardDataRepoScript.new(card_infos_path)
	enemy_repo = EnemyDataRepoScript.new(enemy_infos_path)

func populate_hand_with_all_cards() -> void:
	hand_view.clear_cards()
	var infos: Dictionary = card_repo.get_all()
	if infos.is_empty():
		return
	var cards: Array[CardData] = []
	for key in infos.keys():
		var card_data: CardData = infos[key] as CardData
		cards.append(card_data)
	cards.sort_custom(_sort_card_by_index)
	for data in cards:
		var card: Card = hand_view.add_card()
		_apply_data_to_card(card, data)

func _populate_hand_for_level() -> void:
	if _current_level != null and !_current_level.initial_hand_cards.is_empty():
		hand_view.clear_cards()
		var infos: Dictionary = card_repo.get_all()
		for card_key in _current_level.initial_hand_cards:
			var data: CardData = infos.get(card_key, null) as CardData
			if data == null:
				continue
			var card: Card = hand_view.add_card()
			_apply_data_to_card(card, data)
		return
	populate_hand_with_all_cards()

func _sort_card_by_index(a: CardData, b: CardData) -> bool:
	return a.index < b.index

func _apply_data_to_card(card: Card, data: CardData) -> void:
	var display_name: String = data.display_name
	var numbers: DirectionNumbers = DirectionNumbers.new(
		data.n,
		data.e,
		data.s,
		data.w
	)
	card.set_card_data(display_name, numbers.get_value("n"), numbers.get_value("e"), numbers.get_value("s"), numbers.get_value("w")) # direct set (was set_card_data_numbers)
	card.card_id = data.index
	card.card_effect_id = data.effect_id
	card.set_desc_text(data.desc)
	card.set_art(data.card_art, data.card_art_flipped)

func spawn_enemy_at_center(enemy_key: String) -> void:
	var cell: Cell = _get_center_cell()
	var data: EnemyData = enemy_infos.get(enemy_key, null) as EnemyData
	if data == null or cell == null:
		return
	var unit: UnitCard = create_enemy_unit(enemy_key, data)
	if unit == null:
		return
	spawn_unit_at_cell(unit, cell, data.card_art, data.card_art_flipped)

func _load_and_spawn_level() -> void:
	var level: LevelData = LevelLoaderScript.load_by_index(level_index)
	if level == null:
		return
	_current_level = level
	for entry in level.enemy_spawns:
		var enemy_key: String = str(entry.get("enemy_key", ""))
		if enemy_key == "":
			continue
		var data: EnemyData = enemy_infos.get(enemy_key, null) as EnemyData
		if data == null:
			continue
		var pos: Vector2i = entry.get("pos", Vector2i(0, 0))
		var cell: Cell = board.get_cell_at(pos)
		if cell == null:
			continue
		var unit: UnitCard = create_enemy_unit(enemy_key, data)
		if unit == null:
			continue
		spawn_unit_at_cell(unit, cell, data.card_art, data.card_art_flipped)

func create_enemy_unit(enemy_key: String, data: EnemyData) -> UnitCard:
	if enemy_unit_scene == null:
		return null
	var unit: UnitCard = enemy_unit_scene.instantiate() as UnitCard
	if unit == null:
		return null
	var display_name: String = data.display_name if data.display_name != "" else enemy_key
	var numbers: DirectionNumbers = DirectionNumbers.new(
		data.n,
		data.e,
		data.s,
		data.w
	)
	unit.set_direction_numbers(numbers, true)
	unit.display_name = display_name
	unit.description = data.desc
	unit.effect_id = data.flip_effect_id
	unit.flip_trigger_id = data.flip_trigger_id
	if data.resolver_script != null:
		var resolver_instance: UnitResolver = data.resolver_script.new() as UnitResolver
		if resolver_instance != null:
			if resolver_instance is AttackOrMoveResolver:
				(resolver_instance as AttackOrMoveResolver).debug_log = true
			unit.custom_resolver = resolver_instance
	if enemy_key == "社畜":
		_apply_death_transform(unit, "社畜二阶段")
	return unit

func _apply_death_transform(unit: UnitCard, transform_key: String) -> void:
	var data: EnemyData = enemy_infos.get(transform_key, null) as EnemyData
	if data == null:
		return
	unit.death_behavior = "transform"
	unit.death_transform = data

func spawn_unit_at_cell(unit: UnitCard, cell: Cell, art: Texture2D = null, art_flipped: Texture2D = null) -> bool:
	var placed: bool = board.place_existing_unit(unit, cell)
	if placed:
		unit.set_art(art, art_flipped)
		return true
	unit.queue_free()
	return false

func _get_center_cell() -> Cell:
	return board.get_node("GridContainer/Cell11") as Cell
