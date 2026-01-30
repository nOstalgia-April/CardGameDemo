extends Node
class_name cardInfos

var file_path: NodePath = "res://assets/Data/cardinfos.csv"
var infosDic: Dictionary

func _init() -> void:
	var repo := CardDataRepo.new(str(file_path))
	infosDic = repo.get_all()
