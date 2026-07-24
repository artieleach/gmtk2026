class_name BarrierView extends Node2D


const ABOVE := Vector2i(0, -1)
const LEFT := Vector2i(-1, 0)
const ALONG_ROW := Vector2i(1, 0)
const DOWN_COLUMN := Vector2i(0, 1)

const RUBBLE_EDGE := Color(0.55, 0.60, 0.72, 0.85)
const SHELF := Color(0.88, 0.85, 0.90)

const THICKNESS := 0.3

const SILL_PATHS := {
	1: "res://assets/Window sill 1x1.png",
	3: "res://assets/Window sill 1x3.png",
}
const SILL_BANDS := {
	1: Rect2(0.0, 253.0, 300.0, 47.0),
	3: Rect2(0.0, 1392.0, 900.0, 105.0),
}
const SILL_ART_VALUE := 0.44

var game: Game
var tower_view: TowerView

var _sill_textures: Dictionary = {}
var _bands: Array[Node2D] = []
var _band_faces: Array[int] = [-1, -1, -1]
var _marks: Node2D


func _ready() -> void:
	for width: int in SILL_PATHS:
		_sill_textures[width] = load(SILL_PATHS[width])
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_build_layers()


func _build_layers() -> void:
	var shader: Shader = load("res://view/barrier_light.gdshader")
	for slot in _band_faces.size():
		var band := Node2D.new()
		band.name = "BarrierBand%d" % slot
		band.visible = false
		var material := ShaderMaterial.new()
		material.shader = shader
		band.material = material
		band.draw.connect(_draw_bands.bind(slot))
		add_child(band)
		_bands.append(band)

	_marks = Node2D.new()
	_marks.name = "BarrierMarks"
	_marks.draw.connect(_draw_marks)
	add_child(_marks)


func _process(_delta: float) -> void:
	_update_bands()
	for band in _bands:
		band.queue_redraw()
	_marks.queue_redraw()


func _update_bands() -> void:
	var ready := game != null and tower_view != null and tower_view.light_ready()
	var slot := 0
	if ready:
		var shared := tower_view.light_uniforms()
		for face in HexProjection.FACES:
			if slot >= _bands.size() or not _face_visible(face):
				continue
			var per_face := tower_view.face_light_uniforms(face)
			if per_face.is_empty():
				continue
			var band := _bands[slot]
			band.visible = true
			tower_view.apply_uniforms(band.material, shared)
			tower_view.apply_uniforms(band.material, per_face)
			_band_faces[slot] = face
			slot += 1
	for i in range(slot, _bands.size()):
		_bands[i].visible = false
		_band_faces[i] = -1


func _face_visible(face: int) -> bool:
	return tower_view.is_cell_visible(Vector2i(face * game.tower.cols_per_face, 0))


func _draw_bands(slot: int) -> void:
	var face := _band_faces[slot]
	if face < 0:
		return
	_each_run(face, _draw_band.bind(_bands[slot]))


func _draw_marks() -> void:
	if game == null or tower_view == null or game.tower == null:
		return
	for pos in _visible_cells():
		var cell: Cell = game.tower.at(pos)
		if cell != null and cell.blocked:
			_marks.draw_rect(tower_view.cell_rect(pos).grow(-TowerView.TILE_GAP * 0.5),
				RUBBLE_EDGE, false, 2.0)


func _each_run(face: int, emit: Callable) -> void:
	var cpf := game.tower.cols_per_face
	var rows := _visible_rows()
	for row in range(rows.x, rows.y + 1):
		for local in cpf:
			var pos := Vector2i(face * cpf + local, row)

			if _barred(pos, ABOVE) and _run_start(pos, ABOVE, ALONG_ROW) == pos:
				emit.call(pos, ABOVE, ALONG_ROW)

			if _barred(pos, LEFT):
				var start := _run_start(pos, LEFT, DOWN_COLUMN)
				if start == pos or row == rows.x:
					emit.call(start, LEFT, DOWN_COLUMN)


func _visible_rows() -> Vector2i:
	var camera_row := tower_view.camera_row()
	var half_rows := int(ceil(get_viewport_rect().size.y / (2.0 * Tuning.TILE_H))) + 1
	return Vector2i(
		maxi(0, int(floor(camera_row)) - half_rows),
		mini(game.tower.rows - 1, int(ceil(camera_row)) + half_rows))


func _visible_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var rows := _visible_rows()
	for row in range(rows.x, rows.y + 1):
		for col in game.tower.cols:
			var pos := Vector2i(col, row)
			if tower_view.is_cell_visible(pos):
				cells.append(pos)
	return cells


func _barred(pos: Vector2i, dir: Vector2i) -> bool:
	return game.tower.barred_edge(pos, pos + dir)


func _owner(pos: Vector2i, dir: Vector2i) -> Vector2i:
	var cell: Cell = game.tower.at(pos)
	if cell != null and cell.bars_side(Cell.bar_for(dir)):
		return pos
	return game.tower.wrap_pos(pos + dir)


func _joins(a: Vector2i, b: Vector2i, dir: Vector2i) -> bool:
	if not game.tower.in_bounds(a) or not _barred(a, dir):
		return false
	if game.tower.face_of(a.x) != game.tower.face_of(b.x):
		return false
	return (_owner(a, dir) == game.tower.wrap_pos(a)) \
		== (_owner(b, dir) == game.tower.wrap_pos(b))


func _run_start(pos: Vector2i, dir: Vector2i, step: Vector2i) -> Vector2i:
	var first := game.tower.wrap_pos(pos)
	while _joins(game.tower.wrap_pos(first - step), first, dir):
		first = game.tower.wrap_pos(first - step)
	return first


func _run_end(first: Vector2i, dir: Vector2i, step: Vector2i) -> Vector2i:
	var last := first
	while _joins(game.tower.wrap_pos(last + step), last, dir):
		last = game.tower.wrap_pos(last + step)
	return last


func _draw_band(first: Vector2i, dir: Vector2i, step: Vector2i, canvas: CanvasItem) -> void:
	var last := _run_end(first, dir, step)
	var cells := absi(game.tower.col_delta(first.x, last.x)) + absi(last.y - first.y) + 1
	var colour := _sill_colour(tower_view.cell_shade(first))
	var flip := _owner(first, dir) != game.tower.wrap_pos(first)

	var head := tower_view.cell_rect(first)
	var tail := tower_view.cell_rect(last)
	if dir == ABOVE:
		var thickness := Tuning.TILE_H * THICKNESS
		_draw_sill(canvas, Rect2(head.position.x, head.position.y - thickness * 0.5,
			tail.end.x - head.position.x, thickness),
			cells, head.size.x, colour, false, flip)
	else:
		var thickness := head.size.x * THICKNESS
		_draw_sill(canvas, Rect2(head.position.x - thickness * 0.5, head.position.y,
			thickness, tail.end.y - head.position.y),
			cells, Tuning.TILE_H, colour, true, flip)


func _sill_colour(shade: float) -> Color:
	var colour := SHELF * shade / SILL_ART_VALUE
	colour.a = 1.0
	return colour


func _draw_sill(canvas: CanvasItem, rect: Rect2, cells: int, cell_size: float,
		modulate: Color, upright: bool, flip: bool) -> void:
	var band: Rect2 = SILL_BANDS[1] if cells < 2 else SILL_BANDS[3]
	var tex: Texture2D = _sill_textures.get(1 if cells < 2 else 3)
	if tex == null:
		return

	var length := rect.size.y if upright else rect.size.x
	var thickness := rect.size.x if upright else rect.size.y
	if upright:
		canvas.draw_set_transform(
			rect.position if flip else Vector2(rect.end.x, rect.position.y),
			PI * 0.5, Vector2(1.0, -1.0) if flip else Vector2.ONE)
	elif flip:
		canvas.draw_set_transform(Vector2(rect.position.x, rect.end.y), 0.0,
			Vector2(1.0, -1.0))
	else:
		canvas.draw_set_transform(rect.position, 0.0)

	if cells < 2:
		canvas.draw_texture_rect_region(tex, Rect2(0.0, 0.0, length, thickness),
			band, modulate)
	else:
		var stone := band.size.x / 3.0
		var ends := minf(cell_size, length * 0.5)
		for slice in 3:
			var from := 0.0 if slice == 0 else (ends if slice == 1 else length - ends)
			var to := ends if slice == 0 else (length - ends if slice == 1 else length)
			if to - from <= 0.0:
				continue
			canvas.draw_texture_rect_region(tex,
				Rect2(from, 0.0, to - from, thickness),
				Rect2(band.position + Vector2(stone * float(slice), 0.0),
					Vector2(stone, band.size.y)),
				modulate)

	canvas.draw_set_transform_matrix(Transform2D.IDENTITY)
