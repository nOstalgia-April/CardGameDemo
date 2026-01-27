extends Node2D

@onready var hand_view: Node = $HandView
@onready var board: Node = $Board

var card_infos: cardInfos = cardInfos.new()
@export var enemy_infos_path: String = "res://assets/enemyinfos.csv"
var enemy_infos: Dictionary = {}

func _ready() -> void:
	populate_hand_with_all_cards()
	enemy_infos = _read_csv_as_nested_dict(enemy_infos_path)
	spawn_enemy_at_center("小怪")

func populate_hand_with_all_cards() -> void:
	if hand_view == null:
		return
	if hand_view.has_method("clear_cards"):
		hand_view.call("clear_cards")

	var infos: Dictionary = card_infos.infosDic
	if infos.is_empty():
		return

	var rows: Array[Dictionary] = []
	for key in infos.keys():
		var row: Dictionary = infos[key] as Dictionary
		rows.append(row)

	rows.sort_custom(_sort_by_index)

	for row in rows:
		var card: Control = hand_view.call("add_card") as Control
		if card == null:
			continue
		_apply_row_to_card(card, row)

func _sort_by_index(a: Dictionary, b: Dictionary) -> bool:
	var a_index: int = int(a.get("index", 0))
	var b_index: int = int(b.get("index", 0))
	return a_index < b_index

func _apply_row_to_card(card: Control, row: Dictionary) -> void:
	var display_name: String = str(row.get("base_displayName", ""))
	var n: int = int(row.get("base_n", 0))
	var e: int = int(row.get("base_e", 0))
	var s: int = int(row.get("base_s", 0))
	var w: int = int(row.get("base_w", 0))
	if card.has_method("set_card_data"):
		card.call("set_card_data", display_name, n, e, s, w)

func spawn_enemy_at_center(enemy_key: String) -> void:
	var cell: Node = _get_center_cell()
	if cell == null:
		return
	var row: Dictionary = enemy_infos.get(enemy_key, {}) as Dictionary
	if row.is_empty():
		return
	var display_name: String = str(row.get("base_displayName", enemy_key))
	var n: int = int(row.get("base_n", 0))
	var e: int = int(row.get("base_e", 0))
	var s: int = int(row.get("base_s", 0))
	var w: int = int(row.get("base_w", 0))
	if cell.has_method("spawn_unit"):
		cell.call("spawn_unit", display_name, n, e, s, w, true)

func _get_center_cell() -> Node:
	if board == null:
		return null
	var center: Node = board.get_node_or_null("GridContainer/Cell11")
	return center

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
