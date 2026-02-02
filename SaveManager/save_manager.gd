extends Node

# 存档文件路径
var save_file_path := "user://save_data.json"
func _ready() -> void:
	load_game()

# 保存当前关卡数
func save_game(current_level: int) -> void:
	var file = FileAccess.open(save_file_path, FileAccess.WRITE)
	if file:
		var save_data = {
			"current_level": current_level
		}
		file.store_string(JSON.stringify(save_data))
		file.close()
		print("游戏已保存至:", save_file_path)
	else:
		print("无法打开存档文件进行写入")

# 加载存档数据
func load_game() -> int:
	if not FileAccess.file_exists(save_file_path):
		print("未找到存档文件，从第1关开始")
		return 1  # 默认从第1关开始

	var file = FileAccess.open(save_file_path, FileAccess.READ)
	if file:
		var save_data = JSON.parse_string(file.get_as_text())
		file.close()
		if typeof(save_data) == TYPE_DICTIONARY and save_data.has("current_level"):
			print("加载存档成功，当前关卡:", save_data["current_level"])
			return save_data["current_level"]
		else:
			print("存档文件格式错误，从第1关开始")
			return 1
	else:
		print("无法打开存档文件进行读取")
		return 1
