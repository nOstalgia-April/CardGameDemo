extends Node2D

@onready var hand_view: HandView = %HandView
@onready var board: Board = %Board
@onready var turn_manager: Node2D = %TurnManager

var card_infos: cardInfos = cardInfos.new()
@export var enemy_infos_path: String = "res://assets/enemyinfos.csv"
var enemy_infos: Dictionary = {}

func _ready() -> void:
	populate_hand_with_all_cards()
	enemy_infos = _read_csv_as_nested_dict(enemy_infos_path)
	spawn_enemy_at_center("社畜")
	turn_manager.start_turn()

func populate_hand_with_all_cards() -> void:
	hand_view.clear_cards()

	var infos: Dictionary = card_infos.infosDic
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
	var n: int = int(row.get("base_n", 0))
	var e: int = int(row.get("base_e", 0))
	var s: int = int(row.get("base_s", 0))
	var w: int = int(row.get("base_w", 0))
	card.set_card_data(display_name, n, e, s, w)

func spawn_enemy_at_center(enemy_key: String) -> void:
	var cell: Cell = _get_center_cell()
	var row: Dictionary = enemy_infos.get(enemy_key, {}) as Dictionary
	if row.is_empty():
		return
	var display_name: String = str(row.get("base_displayName", enemy_key))
	var n: int = int(row.get("base_n", 0))
	var e: int = int(row.get("base_e", 0))
	var s: int = int(row.get("base_s", 0))
	var w: int = int(row.get("base_w", 0))
	cell.spawn_unit(display_name, n, e, s, w, true)

func _get_center_cell() -> Cell:
	return board.get_node("GridContainer/Cell11") as Cell

func _read_csv_as_nested_dict(path: String) -> Dictionary:
	var data: Dictionary = {}
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return data
	var headers: PackedStringArray = []
	var first_line: bool = true
	while not file.eof_reached():
		var values: PackedStringArray = file.get_csv_line()
		if first_line:
			headers = values
			first_line = false
		elif values.size() >= 2:
			var key: String = values[0]
			var row_dict: Dictionary = {}
			for i in range(0, headers.size()):
				row_dict[headers[i]] = values[i]
			data[key] = row_dict
	file.close()
	return data
