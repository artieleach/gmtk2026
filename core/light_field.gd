class_name LightField extends RefCounted


enum State {
	DARK,
	LIT,
	SHADED,
}

const MIN_REACH := 0.0001

var _tower: TowerData = null
var front_row: float = 0.0
var _offset_per_depth := Vector2.ZERO
var _max_depth: int = 0
var _casts: bool = false
var _lanterns: Array[Vector3] = []
var _memo: Dictionary = {}


func bind(tower: TowerData, sun: SunModel, turn: int, lanterns: Array = []) -> void:
	_tower = tower
	front_row = sun.front_row(turn)
	_casts = sun.casts_shadows(turn)
	_offset_per_depth = sun.shadow_offset_per_depth(turn)
	_max_depth = tower.max_protrusion_depth()
	_memo.clear()

	_lanterns.clear()
	for pos: Vector2i in lanterns:
		var cell: Cell = tower.at(pos)
		var stood_on := float(cell.protrusion_depth) if cell != null else 0.0
		_lanterns.append(Vector3(pos.x, pos.y, stood_on + Tuning.LANTERN_HEIGHT))


func state_at(pos: Vector2i) -> int:
	if _tower == null or pos.y < 0 or pos.y >= _tower.rows:
		return State.DARK

	var key := Vector2i(_tower.wrap_col(pos.x), pos.y)
	var cached: Variant = _memo.get(key)
	if cached != null:
		return cached

	var result := _resolve(key)
	_memo[key] = result
	return result


func _resolve(pos: Vector2i) -> int:
	var state := _sun_state(pos)
	if state != State.LIT and _lantern_lights(pos):
		return State.LIT
	return state


func _sun_state(pos: Vector2i) -> int:
	if float(pos.y) >= front_row:
		return State.DARK
	return State.SHADED if shadow_margin(Vector2(pos)) >= 0.0 else State.LIT


func shadow_margin(point: Vector2) -> float:
	var limit := float(_max_depth)
	var floor_margin := -limit - 1.0
	if not _casts or limit <= 0.0 or _offset_per_depth.length() < MIN_REACH:
		return floor_margin

	var cell := Vector2i(_texel(point.x), _texel(point.y))
	var here := _depth_at(cell)
	if here > 0.0:
		return here

	var dir := -_offset_per_depth
	var step := Vector2i(1 if dir.x > 0.0 else -1, 1 if dir.y > 0.0 else -1)
	var next := Vector2(INF, INF)
	var span := Vector2(INF, INF)
	if absf(dir.x) > 0.0:
		next.x = (float(cell.x) + 0.5 * float(step.x) - point.x) / dir.x
		span.x = 1.0 / absf(dir.x)
	if absf(dir.y) > 0.0:
		next.y = (float(cell.y) + 0.5 * float(step.y) - point.y) / dir.y
		span.y = 1.0 / absf(dir.y)

	var margin := floor_margin
	for _i in Tuning.MAX_SHADOW_CELLS:
		var enter: float
		if next.x < next.y:
			enter = next.x
			cell.x += step.x
			next.x += span.x
		else:
			enter = next.y
			cell.y += step.y
			next.y += span.y
		if cell.y < 0 or cell.y >= _tower.rows:
			break
		var depth := _depth_at(cell)
		if depth > 0.0:
			margin = maxf(margin, depth - enter)
			if margin >= 0.0:
				break
		if enter > limit:
			break
	return margin


func _depth_at(cell: Vector2i) -> float:
	var wrapped: Cell = _tower.cells[cell.y * _tower.cols + _tower.wrap_col(cell.x)]
	return float(wrapped.protrusion_depth)


func _texel(coord: float) -> int:
	return int(floor(coord + 0.5))


func _lantern_lights(pos: Vector2i) -> bool:
	if _lanterns.is_empty():
		return false
	var point := Vector2(pos)
	for lantern in _lanterns:
		var delta := _wall_delta(point, Vector2(lantern.x, lantern.y))
		if delta.length() > Tuning.LANTERN_RADIUS:
			continue
		if not _blocked_from_lantern(point, delta, lantern.z):
			return true
	return false


func _blocked_from_lantern(point: Vector2, delta: Vector2, source_depth: float) -> bool:
	var cell := Vector2i(_texel(point.x), _texel(point.y))
	if _depth_at(cell) > 0.0:
		return true

	var dir := -delta
	var step := Vector2i(1 if dir.x > 0.0 else -1, 1 if dir.y > 0.0 else -1)
	var next := Vector2(INF, INF)
	var span := Vector2(INF, INF)
	if absf(dir.x) > 0.0:
		next.x = (float(cell.x) + 0.5 * float(step.x) - point.x) / dir.x
		span.x = 1.0 / absf(dir.x)
	if absf(dir.y) > 0.0:
		next.y = (float(cell.y) + 0.5 * float(step.y) - point.y) / dir.y
		span.y = 1.0 / absf(dir.y)

	for _i in Tuning.MAX_LANTERN_CELLS:
		var enter: float
		if next.x < next.y:
			enter = next.x
			cell.x += step.x
			next.x += span.x
		else:
			enter = next.y
			cell.y += step.y
			next.y += span.y
		if enter > 1.0:
			return false
		if cell.y < 0 or cell.y >= _tower.rows:
			return true
		if _depth_at(cell) > source_depth * enter:
			return true
	return false


func _wall_delta(from: Vector2, to: Vector2) -> Vector2:
	var cols := float(_tower.cols)
	var dx := from.x - to.x
	dx -= cols * floor(dx / cols + 0.5)
	return Vector2(dx, from.y - to.y)


func is_safe(pos: Vector2i) -> bool:
	return state_at(pos) != State.LIT
