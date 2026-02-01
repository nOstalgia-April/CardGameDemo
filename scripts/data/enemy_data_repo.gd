extends RefCounted

const EnemyDataScript = preload("res://scripts/data/enemy_data.gd")
const FALLBACK_ENEMY_PATHS: Array[String] = [
	"res://Data/enemies/enemy_小怪.tres",
	"res://Data/enemies/enemy_小怪1.tres",
	"res://Data/enemies/enemy_小怪2.tres",
	"res://Data/enemies/enemy_社畜.tres",
	"res://Data/enemies/enemy_社畜二阶段.tres",
	"res://Data/enemies/enemy_章鱼.tres",
	"res://Data/enemies/enemy_蜘蛛.tres",
	"res://Data/enemies/enemy_石头.tres"
]

var folder_path: String = "res://Data/enemies"
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

func get_enemy(enemy_key: String) -> EnemyData:
	return infos.get(enemy_key, null) as EnemyData

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
		var enemy: EnemyData = res as EnemyData
		if enemy == null:
			file_name = dir.get_next()
			continue
		var key: String = enemy.enemy_key
		if key == "":
			key = file_name.get_basename()
		data[key] = enemy
		file_name = dir.get_next()
	dir.list_dir_end()
	if data.is_empty():
		return _load_fallback()
	return data

func _load_fallback() -> Dictionary:
	var data: Dictionary = {}
	for res_path in FALLBACK_ENEMY_PATHS:
		var res: Resource = ResourceLoader.load(res_path)
		var enemy: EnemyData = res as EnemyData
		if enemy == null:
			continue
		var key: String = enemy.enemy_key
		if key == "":
			key = res_path.get_file().get_basename()
		data[key] = enemy
	return data
