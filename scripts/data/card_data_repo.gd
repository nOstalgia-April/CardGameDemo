extends RefCounted
class_name CardDataRepo

const CardDataScript = preload("res://scripts/data/card_data.gd")
const FALLBACK_CARD_PATHS: Array[String] = [
	"res://Data/cards/card_Angry.tres",
	"res://Data/cards/card_Happy.tres",
	"res://Data/cards/card_Jealous.tres",
	"res://Data/cards/card_Lovely.tres",
	"res://Data/cards/card_Sad.tres",
	"res://Data/cards/card_Scared.tres"
]

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
		return _load_fallback()
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
	if data.is_empty():
		return _load_fallback()
	return data

func _load_fallback() -> Dictionary:
	var data: Dictionary = {}
	for res_path in FALLBACK_CARD_PATHS:
		var res: Resource = ResourceLoader.load(res_path)
		var card: CardData = res as CardData
		if card == null:
			continue
		var key: String = card.card_key
		if key == "":
			key = res_path.get_file().get_basename()
		data[key] = card
	return data
