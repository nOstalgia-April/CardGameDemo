extends RefCounted
class_name CardDataRepo

var file_path: String = "res://assets/cardinfos.csv"
var infos: Dictionary = {}

func _init(path: String = "") -> void:
	if path != "":
		file_path = path
	infos = read_csv_as_nested_dict(file_path)

func reload(path: String = "") -> void:
	if path != "":
		file_path = path
	infos = read_csv_as_nested_dict(file_path)

func get_all() -> Dictionary:
	return infos

func read_csv_as_nested_dict(path: String) -> Dictionary:
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
