extends RefCounted
class_name DirUtils

static func dir_to_vec(dir: int) -> Vector2i:
	match dir:
		0:
			return Vector2i(0, -1)
		1:
			return Vector2i(1, 0)
		2:
			return Vector2i(0, 1)
		3:
			return Vector2i(-1, 0)
	return Vector2i.ZERO

static func vec_to_dir(vec: Vector2i) -> int:
	if vec == Vector2i(0, -1):
		return 0
	if vec == Vector2i(1, 0):
		return 1
	if vec == Vector2i(0, 1):
		return 2
	if vec == Vector2i(-1, 0):
		return 3
	return -1

static func opposite_dir(dir: int) -> int:
	match dir:
		0:
			return 2
		1:
			return 3
		2:
			return 0
		3:
			return 1
	return 0

static func dir_name(dir: int) -> String:
	match dir:
		0:
			return "N"
		1:
			return "E"
		2:
			return "S"
		3:
			return "W"
	return ""

static func clamp_board_pos(pos: Vector2i, board_size: Vector2i) -> Vector2i:
	var x: int = clamp(pos.x, 0, max(0, board_size.x - 1))
	var y: int = clamp(pos.y, 0, max(0, board_size.y - 1))
	return Vector2i(x, y)

static func is_valid_pos(pos: Vector2i, board_size: Vector2i) -> bool:
	return pos.x >= 0 and pos.y >= 0 and pos.x < board_size.x and pos.y < board_size.y
