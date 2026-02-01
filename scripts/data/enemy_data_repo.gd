extends RefCounted

const EnemyDataScript = preload("res://scripts/data/enemy_data.gd")
const FALLBACK_ENEMY_PATHS: Array[String] = [
	"res://Data/enemies/enemy_小怪.tres",
	"res://Data/enemies/level_1/enemy_小怪1.tres",
	"res://Data/enemies/level_2/enemy_小怪2.tres",
	"res://Data/enemies/level_1/enemy_社畜.tres",
	"res://Data/enemies/level_1/enemy_社畜二阶段.tres",
	"res://Data/enemies/enemy_社畜.tres",
	"res://Data/enemies/enemy_社畜二阶段.tres",
	"res://Data/enemies/enemy_章鱼.tres",
	"res://Data/enemies/enemy_蜘蛛.tres",
	"res://Data/enemies/enemy_石头.tres",
	"res://Data/enemies/level_4/enemy_长矛.tres"
]

var folder_path: String = "res://Data/enemies"
var infos: Dictionary = {}

func _init(path: String = "") -> void:
	if path != "":
		folder_path = path
	infos = _load_folder(folder_path)
	if infos.is_empty():
		infos = _load_fallback()

func reload(path: String = "") -> void:
	if path != "":
		folder_path = path
	infos = _load_folder(folder_path)
	if infos.is_empty():
		infos = _load_fallback()

func get_all() -> Dictionary:
	return infos

func get_enemy(enemy_key: String) -> EnemyData:
	return infos.get(enemy_key, null) as EnemyData

func _load_folder(path: String) -> Dictionary:
	var data: Dictionary = {}
	var dir: DirAccess = DirAccess.open(path)
	if dir == null:
		return {}
	
	var subdirs: Array[String] = []
	var files: Array[String] = []

	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if dir.current_is_dir():
			if file_name != "." and file_name != "..":
				subdirs.append(file_name)
		else:
			var ext_file_name = file_name
			if file_name.ends_with(".remap"):
				ext_file_name = file_name.trim_suffix(".remap")
				
			if ext_file_name.ends_with(".tres") or ext_file_name.ends_with(".res"):
				files.append(ext_file_name)
		file_name = dir.get_next()
	dir.list_dir_end()
	
	# First load files in current directory
	for f in files:
		var res_path: String = path.path_join(f)
		var res: Resource = ResourceLoader.load(res_path)
		var enemy: EnemyData = res as EnemyData
		if enemy != null:
			var key: String = enemy.enemy_key
			if key == "":
				key = f.get_basename()
			data[key] = enemy
			
	# Then load subdirectories (overwriting parent files if keys collide)
	for d in subdirs:
		var sub_path = path.path_join(d)
		data.merge(_load_folder(sub_path), true)
		
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
