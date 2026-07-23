class_name TowerData extends RefCounted


const FACES := 6

const DIRS: Array[Vector2i] = [
	Vector2i(0, -1), Vector2i(1, -1), Vector2i(1, 0), Vector2i(1, 1),
	Vector2i(0, 1), Vector2i(-1, 1), Vector2i(-1, 0), Vector2i(-1, -1),
]

var cols: int
var rows: int
var cols_per_face: int
var cells: Array[Cell] = []

var _max_protrusion_depth: int = -1


func _init(p_cols: int = Tuning.COLS, p_rows: int = Tuning.ROWS) -> void:
	assert(p_cols % FACES == 0, "column count must divide evenly into %d faces" % FACES)
	cols = p_cols
	rows = p_rows
	cols_per_face = cols / FACES
	cells.resize(cols * rows)
	for i in cells.size():
		cells[i] = Cell.new()


func wrap_col(col: int) -> int:
	return ((col % cols) + cols) % cols


func wrap_pos(pos: Vector2i) -> Vector2i:
	return Vector2i(wrap_col(pos.x), pos.y)


func in_bounds(pos: Vector2i) -> bool:
	return pos.y >= 0 and pos.y < rows


func index(pos: Vector2i) -> int:
	return pos.y * cols + wrap_col(pos.x)


func at(pos: Vector2i) -> Cell:
	if not in_bounds(pos):
		return null
	return cells[index(pos)]


func face_of(col: int) -> int:
	return wrap_col(col) / cols_per_face


func face_delta(from_face: int, to_face: int) -> int:
	return wrapi(to_face - from_face, -(FACES / 2), FACES / 2)


func col_delta(from_col: int, to_col: int) -> int:
	return wrapi(to_col - from_col, -(cols / 2), cols / 2)


func invalidate_protrusion_cache() -> void:
	_max_protrusion_depth = -1


func max_protrusion_depth() -> int:
	if _max_protrusion_depth < 0:
		_max_protrusion_depth = 0
		for cell in cells:
			_max_protrusion_depth = maxi(_max_protrusion_depth, cell.protrusion_depth)
	return _max_protrusion_depth


func is_blocked(pos: Vector2i) -> bool:
	var cell: Cell = at(pos)
	return cell == null or cell.blocked


func barred_edge(from: Vector2i, to: Vector2i) -> bool:
	if wrap_col(from.x) != wrap_col(to.x):
		return false
	if absi(from.y - to.y) != 1:
		return false
	var lower: Vector2i = to if to.y > from.y else from
	var cell: Cell = at(lower)
	return cell != null and cell.casts_shadow()


func can_player_enter(from: Vector2i, to: Vector2i) -> bool:
	return in_bounds(to) and not is_blocked(to) and not barred_edge(from, to)


func neighbours(pos: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for dir in DIRS:
		var target := wrap_pos(pos + dir)
		if in_bounds(target):
			result.append(target)
	return result
