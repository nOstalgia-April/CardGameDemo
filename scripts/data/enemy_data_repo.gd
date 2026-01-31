extends RefCounted

const EnemyDataScript = preload("res://scripts/data/enemy_data.gd")

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
	return data
