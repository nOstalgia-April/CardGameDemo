extends RefCounted
class_name CardDataRepo

const CardDataScript = preload("res://scripts/data/card_data.gd")

var folder_path: String = "res://Data/cards"
var infos: Dictionary = {}

func _init(path: String = "") -> void:
	if path != "":
		folder_path = path
	infos = _load_folder(folder_path)

func reload(path: String = "") -> void:
	if path != "":
		folder_path = path
	infos = _load_folder(folder_path)

func get_all() -> Dictionary:
	return infos

func get_card(card_key: String) -> CardData:
	return infos.get(card_key, null) as CardData

func _load_folder(path: String) -> Dictionary:
	var data: Dictionary = {}
	var dir: DirAccess = DirAccess.open(path)
	if dir == null:
		return data
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if dir.current_is_dir():
			file_name = dir.get_next()
			continue
		if !(file_name.ends_with(".tres") or file_name.ends_with(".res")):
			file_name = dir.get_next()
			continue
		var res_path: String = path.path_join(file_name)
		var res: Resource = ResourceLoader.load(res_path)
		var card: CardData = res as CardData
		if card == null:
			file_name = dir.get_next()
			continue
		var key: String = card.card_key
		if key == "":
			key = file_name.get_basename()
		data[key] = card
		file_name = dir.get_next()
	dir.list_dir_end()
	return data
