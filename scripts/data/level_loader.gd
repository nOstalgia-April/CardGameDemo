extends Node
class_name LevelLoader

static func load_by_index(level_index: int) -> LevelData:
	var path := "res://Data/levels/level_%d.tres" % level_index
	var res := load(path)
	return res as LevelData
