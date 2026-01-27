extends Control

@onready var grid: GridContainer = $GridContainer
var cell_map: Dictionary = {}

func _ready() -> void:
	add_to_group("board")
	_index_cells()

func get_neighbor_cells(cell: Node) -> Array[Node]:
	var pos: Vector2i = _get_cell_pos(cell)
	if pos == Vector2i(-1, -1):
		return []
	var neighbors: Array[Node] = []
	var dirs: Array[Vector2i] = [
		Vector2i(0, -1),
		Vector2i(1, 0),
		Vector2i(0, 1),
		Vector2i(-1, 0),
	]
	for dir in dirs:
		var npos: Vector2i = pos + dir
		var neighbor: Node = cell_map.get(npos, null)
		if neighbor != null:
			neighbors.append(neighbor)
	return neighbors

func _index_cells() -> void:
	cell_map.clear()
	if grid == null:
		return
	var children: Array[Node] = grid.get_children()
	for i in range(children.size()):
		var cell: Node = children[i]
		if cell == null:
			continue
		var pos: Vector2i = _parse_cell_name(cell.name)
		if pos == Vector2i(-1, -1):
			var columns: int = max(1, grid.columns)
			pos = Vector2i(i % columns, i / columns)
		cell.set_meta("grid_x", pos.x)
		cell.set_meta("grid_y", pos.y)
		cell_map[pos] = cell

func _parse_cell_name(name: String) -> Vector2i:
	if name.begins_with("Cell") and name.length() >= 6:
		var x_str: String = name.substr(4, 1)
		var y_str: String = name.substr(5, 1)
		if x_str.is_valid_int() and y_str.is_valid_int():
			return Vector2i(int(x_str), int(y_str))
	return Vector2i(-1, -1)

func _get_cell_pos(cell: Node) -> Vector2i:
	if cell == null:
		return Vector2i(-1, -1)
	if cell.has_meta("grid_x") and cell.has_meta("grid_y"):
		return Vector2i(int(cell.get_meta("grid_x")), int(cell.get_meta("grid_y")))
	return _parse_cell_name(cell.name)
