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

var windows: Array = []


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


func is_blocked(pos: Vector2i) -> bool:
	var cell: Cell = at(pos)
	return cell == null or cell.blocked


func is_window(pos: Vector2i) -> bool:
	var cell: Cell = at(pos)
	return cell != null and cell.kind == Cell.Kind.WINDOW


func player_can_stand(pos: Vector2i) -> bool:
	return in_bounds(pos) and not is_blocked(pos) and not is_window(pos)


func barred_edge(from: Vector2i, to: Vector2i) -> bool:
	var dcol := col_delta(from.x, to.x)
	var drow := to.y - from.y
	var flag := Cell.bar_for(Vector2i(dcol, drow))
	if flag != 0:
		var a: Cell = at(from)
		if a != null and a.bars_side(flag):
			return true
		var b: Cell = at(to)
		return b != null and b.bars_side(Cell.opposite(flag))
	if absi(dcol) == 1 and absi(drow) == 1:
		return _elbow_barred(from, Vector2i(from.x + dcol, from.y), to) \
			and _elbow_barred(from, Vector2i(from.x, to.y), to)
	return false


func _elbow_barred(from: Vector2i, mid: Vector2i, to: Vector2i) -> bool:
	return barred_edge(from, mid) or barred_edge(mid, to)


func can_player_enter(from: Vector2i, to: Vector2i) -> bool:
	return player_can_stand(to) and not barred_edge(from, to)


func neighbours(pos: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for dir in DIRS:
		var target := wrap_pos(pos + dir)
		if in_bounds(target):
			result.append(target)
	return result


func unwall_edge(from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	var flag := Cell.bar_for(Vector2i(col_delta(from.x, to.x), to.y - from.y))
	if flag == 0:
		return []
	var changed: Array[Vector2i] = []
	if _drop_bars(from, flag):
		changed.append(wrap_pos(from))
	if _drop_bars(to, Cell.opposite(flag)):
		changed.append(wrap_pos(to))
	return changed


func _drop_bars(pos: Vector2i, flags: int) -> bool:
	var cell: Cell = at(pos)
	if cell == null or cell.bars & flags == 0:
		return false
	cell.bars &= ~flags
	if cell.bars == 0:
		cell.kind = Cell.Kind.WALL
	return true
