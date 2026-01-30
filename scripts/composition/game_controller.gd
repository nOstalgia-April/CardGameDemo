extends Node2D

@onready var hand_view: HandView = %HandView
@onready var board: Board = %Board
@onready var turn_manager: TurnManager = %TurnManager
@onready var root: Control = %Root

@export_group("Data")
@export var card_infos_path: String = "res://assets/cardinfos.csv"
@export var enemy_infos_path: String = "res://assets/enemyinfos.csv"
@export var enemy_unit_scene: PackedScene
@export_group("")

@export_group("ScreenShake")
@export var shake_intensity_default: float = 12.0
@export var shake_duration_default: float = 0.15
@export_group("")
@export var BGM : AudioStream

const CardDataRepoScript = preload("res://scripts/data/card_data_repo.gd")
const EnemyDataRepoScript = preload("res://scripts/data/enemy_data_repo.gd")

var card_repo
var enemy_repo
var enemy_infos: Dictionary = {}
var shake_intensity: float = 0.0
var shake_duration: float = 0.0
var shake_time_left: float = 0.0
var is_shaking: bool = false
var base_position: Vector2 = Vector2.ZERO
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _ready() -> void:
	SoundManager.play_bgm(BGM)
	_rng.randomize()
	BattleEventBus.connect("screen_shake_requested", Callable(self, "_on_screen_shake_requested"))
	_init_repos()
	populate_hand_with_all_cards()
	enemy_infos = enemy_repo.get_all()
	spawn_enemy_at_center("社畜")
	if turn_manager != null:
		turn_manager.start_turn()

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
	var rows: Array[Dictionary] = []
	for key in infos.keys():
		var row: Dictionary = infos[key] as Dictionary
		rows.append(row)
	rows.sort_custom(_sort_by_index)
	for row in rows:
		var card: Card = hand_view.add_card()
		_apply_row_to_card(card, row)

func _sort_by_index(a: Dictionary, b: Dictionary) -> bool:
	var a_index: int = int(a.get("index", 0))
	var b_index: int = int(b.get("index", 0))
	return a_index < b_index

func _apply_row_to_card(card: Card, row: Dictionary) -> void:
	var display_name: String = str(row.get("base_displayName", ""))
	var numbers: DirectionNumbers = DirectionNumbers.new(
		int(row.get("base_n", 0)),
		int(row.get("base_e", 0)),
		int(row.get("base_s", 0)),
		int(row.get("base_w", 0))
	)
	card.set_card_data(display_name, numbers.get_value("n"), numbers.get_value("e"), numbers.get_value("s"), numbers.get_value("w")) # direct set (was set_card_data_numbers)
	var index: int = int(row.get("index", 0))
	_apply_effect_to_card(card, index)

func _apply_effect_to_card(card: Card, index: int) -> void:
	var effect_id: String = ""
	var desc: String = ""
	match index:
		1:
			effect_id = "charge"
			desc = "冲锋：放置时消耗一次翻牌，并对四周发动一次优势攻击"
		2:
			effect_id = "rotate"
			desc = "翻牌：自身顺时针旋转，邻格逆时针旋转"
		3:
			effect_id = "swap"
			desc = "翻牌：下一次左键可与目标换位"
		4:
			effect_id = "knockback"
			desc = "翻牌：造成/受到伤害会击退"
		5:
			effect_id = "heal_adjacent"
			desc = "翻牌：治疗相邻棋子接壤数字至满额"
		6:
			effect_id = "heal_self"
			desc = "翻牌：治疗自身四维至满额"
	if effect_id != "":
		card.card_effect_id = effect_id
		card.set_desc_text(desc)

func spawn_enemy_at_center(enemy_key: String) -> void:
	var cell: Cell = _get_center_cell()
	var unit: UnitCard = create_enemy_unit(enemy_key)
	if unit == null or cell == null:
		return
	spawn_unit_at_cell(unit, cell)

func create_enemy_unit(enemy_key: String) -> UnitCard:
	var row: Dictionary = enemy_infos.get(enemy_key, {}) as Dictionary
	if row.is_empty():
		return null
	if enemy_unit_scene == null:
		return null
	var unit: UnitCard = enemy_unit_scene.instantiate() as UnitCard
	if unit == null:
		return null
	var display_name: String = str(row.get("base_displayName", enemy_key))
	var numbers: DirectionNumbers = DirectionNumbers.new(
		int(row.get("base_n", 0)),
		int(row.get("base_e", 0)),
		int(row.get("base_s", 0)),
		int(row.get("base_w", 0))
	)
	unit.set_direction_numbers(numbers, true)
	if enemy_key == "社畜":
		var resolver: AttackOrMoveResolver = load("res://scripts/resolvers/attack_or_move_resolver.gd").new()
		resolver.debug_log = true
		unit.custom_resolver = resolver
		_apply_death_transform(unit, "社畜二阶段")
	else:
		unit.custom_resolver = AdjacentAttackResolver.new()
	return unit

func _apply_death_transform(unit: UnitCard, transform_key: String) -> void:
	var row: Dictionary = enemy_infos.get(transform_key, {}) as Dictionary
	if row.is_empty():
		return
	unit.death_behavior = "transform"
	unit.death_transform = {
		"display_name": str(row.get("base_displayName", transform_key)),
		"n": int(row.get("base_n", 0)),
		"e": int(row.get("base_e", 0)),
		"s": int(row.get("base_s", 0)),
		"w": int(row.get("base_w", 0)),
	}

func spawn_unit_at_cell(unit: UnitCard, cell: Cell) -> bool:
	var placed: bool = board.place_existing_unit(unit, cell)
	if placed:
		return true
	unit.queue_free()
	return false

func _get_center_cell() -> Cell:
	return board.get_node("GridContainer/Cell11") as Cell
