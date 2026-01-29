extends RefCounted
class_name DirectionNumbers

var values: Dictionary = {
	"n": 0,
	"e": 0,
	"s": 0,
	"w": 0,
}

func _init(n: int = 0, e: int = 0, s: int = 0, w: int = 0) -> void:
	values = {
		"n": n,
		"e": e,
		"s": s,
		"w": w,
	}

static func from_dict(data: Dictionary) -> DirectionNumbers:
	var n: int = int(data.get("n", 0))
	var e: int = int(data.get("e", 0))
	var s: int = int(data.get("s", 0))
	var w: int = int(data.get("w", 0))
	return DirectionNumbers.new(n, e, s, w)

func get_value(key: String) -> int:
	return int(values.get(key.to_lower(), 0))

func set_value(key: String, value: int) -> void:
	values[key.to_lower()] = value

func to_dict() -> Dictionary:
	return values.duplicate()

func clone() -> DirectionNumbers:
	var copy: DirectionNumbers = DirectionNumbers.new()
	copy.values = values.duplicate()
	return copy

func rotate(clockwise: bool) -> void:
	var n: int = get_value("n")
	var e: int = get_value("e")
	var s: int = get_value("s")
	var w: int = get_value("w")
	if clockwise:
		set_value("n", w)
		set_value("e", n)
		set_value("s", e)
		set_value("w", s)
	else:
		set_value("n", e)
		set_value("e", s)
		set_value("s", w)
		set_value("w", n)
