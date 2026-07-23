class_name TowerView extends Node2D


const SKY := Color(0.05, 0.05, 0.10)

const KIND_COLORS := {
	Cell.Kind.WALL: Color(0.44, 0.42, 0.47),
	Cell.Kind.BRICK: Color(0.38, 0.36, 0.41),
	Cell.Kind.LEDGE: Color(0.56, 0.53, 0.57),
	Cell.Kind.CORNICE: Color(0.60, 0.57, 0.61),
	Cell.Kind.WINDOW: Color(0.13, 0.11, 0.17),
	Cell.Kind.RUBBLE: Color(0.24, 0.22, 0.26),
	Cell.Kind.ALTAR: Color(0.62, 0.16, 0.22),
}
const COLOR_BLOCKED := Color(0.24, 0.22, 0.26)
const SOLID_EDGE := Color(0.92, 0.88, 0.78)
const RUBBLE_EDGE := Color(0.55, 0.60, 0.72, 0.85)
const SHELF := Color(0.88, 0.85, 0.90)

const LIGHT_LIT := Color(1.00, 0.90, 0.60, 0.62)
const LIGHT_SHADED := Color(0.19, 0.19, 0.35, 0.74)
const LIGHT_DARK := Color(0.05, 0.06, 0.12, 0.74)
const LIGHT_FRONT_LINE := Color(1.0, 0.88, 0.50, 0.90)
const LIGHT_LANTERN := Color(1.00, 0.72, 0.34, 0.66)

const PROTRUSION_SHIFT := 0.08
const EDGE_SHADE := 0.5
const TILE_GAP := 2.0

var game: Game
var proj := HexProjection.new()

var _camera_row: float = 0.0
var _yaw_target: float = 0.0
var _face: int = 0
var _depth_texture: ImageTexture
var _depth_image: Image
var _light_rects: Array[ColorRect] = []
var _solid_marks: Node2D


func _ready() -> void:
	_build_light_rects()
	if game != null:
		game.run_started.connect(_on_run_started)
		game.tower_changed.connect(_on_tower_changed)


func _build_light_rects() -> void:
	var shader: Shader = load("res://view/wall_light.gdshader")
	for i in 3:
		var rect := ColorRect.new()
		rect.name = "WallLight%d" % i
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rect.visible = false
		var material := ShaderMaterial.new()
		material.shader = shader
		material.set_shader_parameter("lit_color", LIGHT_LIT)
		material.set_shader_parameter("lantern_color", LIGHT_LANTERN)
		material.set_shader_parameter("shaded_color", LIGHT_SHADED)
		material.set_shader_parameter("dark_color", LIGHT_DARK)
		material.set_shader_parameter("front_line_color", LIGHT_FRONT_LINE)
		rect.material = material
		add_child(rect)
		_light_rects.append(rect)

	_solid_marks = Node2D.new()
	_solid_marks.name = "SolidMarks"
	_solid_marks.draw.connect(_draw_solid_marks)
	add_child(_solid_marks)


func _on_run_started() -> void:
	if game == null or game.player == null:
		return
	_face = game.tower.face_of(game.player.pos.x)
	_yaw_target = HexProjection.yaw_for_face(_face)
	proj.yaw = _yaw_target
	_camera_row = float(game.player.pos.y)
	_build_depth_texture()


func _build_depth_texture() -> void:
	var tower := game.tower
	var bytes := PackedByteArray()
	bytes.resize(tower.cols * tower.rows)
	for i in tower.cells.size():
		bytes[i] = clampi(tower.cells[i].protrusion_depth, 0, 255)
	_depth_image = Image.create_from_data(tower.cols, tower.rows, false, Image.FORMAT_R8, bytes)
	_depth_texture = ImageTexture.create_from_image(_depth_image)
	for rect in _light_rects:
		rect.material.set_shader_parameter("depth_tex", _depth_texture)
		rect.material.set_shader_parameter("grid_size", Vector2(tower.cols, tower.rows))


func _on_tower_changed(pos: Vector2i) -> void:
	if _depth_image == null or _depth_texture == null:
		return
	var depth := float(game.tower.at(pos).protrusion_depth) / 255.0
	_depth_image.set_pixel(pos.x, pos.y, Color(depth, 0.0, 0.0))
	_depth_texture.update(_depth_image)


func _process(delta: float) -> void:
	if game != null and game.player != null:
		_track_player(delta)
	_update_light_rects()
	queue_redraw()
	if _solid_marks != null:
		_solid_marks.queue_redraw()


func _track_player(delta: float) -> void:
	var face := game.tower.face_of(game.player.pos.x)
	if face != _face:
		_yaw_target -= float(game.tower.face_delta(_face, face)) * HexProjection.FACE_ARC
		_face = face

	var rotate_speed := HexProjection.FACE_ARC / Tuning.ROTATE_SECONDS
	proj.yaw = move_toward(proj.yaw, _yaw_target, rotate_speed * delta)

	var follow := 1.0 - exp(-Tuning.CAMERA_FOLLOW_SPEED * delta)
	_camera_row = lerpf(_camera_row, float(game.player.pos.y), follow)


func is_rotating() -> bool:
	return absf(proj.yaw - _yaw_target) > 0.0001


func origin() -> Vector2:
	return get_viewport_rect().size * 0.5


func cell_rect(pos: Vector2i) -> Rect2:
	var col := game.tower.wrap_col(pos.x)
	var width := proj.column_width(proj.face_of(col))
	var centre := origin() + Vector2(
		proj.column_center_x(col),
		(float(pos.y) - _camera_row) * Tuning.TILE_H)
	return Rect2(centre - Vector2(width, Tuning.TILE_H) * 0.5, Vector2(width, Tuning.TILE_H))


func is_cell_visible(pos: Vector2i) -> bool:
	return proj.is_face_visible(proj.face_of(game.tower.wrap_col(pos.x)))


func _visible_lanterns() -> Array:
	var packed: Array = []
	for pos: Vector2i in game.lantern_positions():
		var stood_on := float(game.tower.at(pos).protrusion_depth)
		packed.append(Vector4(pos.x, pos.y,
			stood_on + Tuning.LANTERN_HEIGHT, Tuning.LANTERN_RADIUS))
	return packed


func _update_light_rects() -> void:
	if game == null or game.tower == null or _depth_texture == null:
		return
	var viewport := get_viewport_rect().size
	var base := origin()
	var sun := game.sun
	var turn := game.turn
	var light := game.light
	var offset := sun.shadow_offset_per_depth(turn)
	var max_depth := float(game.tower.max_protrusion_depth())

	var v_top := _camera_row - base.y / Tuning.TILE_H
	var v_bottom := _camera_row + (viewport.y - base.y) / Tuning.TILE_H

	var lanterns := _visible_lanterns()

	var slot := 0
	for face in HexProjection.FACES:
		if not proj.is_face_visible(face) or slot >= _light_rects.size():
			continue
		var cpf := proj.cols_per_face
		var half_width := proj.column_width(face) * 0.5
		var left := base.x + proj.column_center_x(face * cpf) - half_width
		var right := base.x + proj.column_center_x(face * cpf + cpf - 1) + half_width
		if right - left < 1.0:
			continue

		var rect := _light_rects[slot]
		rect.visible = true
		rect.position = Vector2(left, 0.0)
		rect.size = Vector2(right - left, viewport.y)

		var material: ShaderMaterial = rect.material
		material.set_shader_parameter("wall_min", Vector2(float(face * cpf) - 0.5, v_top))
		material.set_shader_parameter("wall_max", Vector2(float(face * cpf + cpf) - 0.5, v_bottom))
		material.set_shader_parameter("front_row", light.front_row)
		material.set_shader_parameter("offset_per_depth", offset)
		material.set_shader_parameter("max_depth", max_depth)
		material.set_shader_parameter("casts_shadows", sun.casts_shadows(turn))
		material.set_shader_parameter("face_shade", lerpf(EDGE_SHADE, 1.0, proj.face_facing(face)))
		material.set_shader_parameter("lantern_count", lanterns.size())
		if not lanterns.is_empty():
			material.set_shader_parameter("lanterns", lanterns)
		slot += 1

	for i in range(slot, _light_rects.size()):
		_light_rects[i].visible = false


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, get_viewport_rect().size), SKY)
	if game == null or game.tower == null:
		return

	var base := origin()
	var half_rows := int(ceil(get_viewport_rect().size.y / (2.0 * Tuning.TILE_H))) + 1
	var first_row := maxi(0, int(floor(_camera_row)) - half_rows)
	var last_row := mini(game.tower.rows - 1, int(ceil(_camera_row)) + half_rows)

	for face in HexProjection.FACES:
		if not proj.is_face_visible(face):
			continue
		_draw_face(face, base, first_row, last_row)


func _draw_face(face: int, base: Vector2, first_row: int, last_row: int) -> void:
	var shade := lerpf(EDGE_SHADE, 1.0, proj.face_facing(face))
	var width := proj.column_width(face)
	if width <= TILE_GAP:
		return

	for local in proj.cols_per_face:
		var col := face * proj.cols_per_face + local
		var x := base.x + proj.column_center_x(col)
		for row in range(first_row, last_row + 1):
			var cell: Cell = game.tower.at(Vector2i(col, row))
			if cell == null:
				continue
			var y := base.y + (float(row) - _camera_row) * Tuning.TILE_H
			var colour := _tile_colour(cell) * shade
			colour.a = 1.0
			draw_rect(Rect2(
				x - width * 0.5 + TILE_GAP * 0.5,
				y - Tuning.TILE_H * 0.5 + TILE_GAP * 0.5,
				width - TILE_GAP,
				Tuning.TILE_H - TILE_GAP), colour)

	for local in _shelf_order(face):
		var col := face * proj.cols_per_face + local
		var x := base.x + proj.column_center_x(col)
		for row in range(first_row, last_row + 1):
			var cell: Cell = game.tower.at(Vector2i(col, row))
			if cell == null or not cell.casts_shadow():
				continue
			var y := base.y + (float(row) - _camera_row) * Tuning.TILE_H
			_draw_protrusion(face, cell, x, y, width, shade)


func _shelf_order(face: int) -> Array[int]:
	var order: Array[int] = []
	for local in proj.cols_per_face:
		order.append(local)
	if sin(proj.face_angle(face)) > 0.0:
		order.reverse()
	return order


func _protrusion_span(face: int, depth: int, x: float, width: float) -> Vector2:
	var offset := proj.protrusion_offset_x(face, float(depth) * PROTRUSION_SHIFT)
	return Vector2(
		x - width * 0.5 + minf(0.0, offset),
		x + width * 0.5 + maxf(0.0, offset))


func _draw_protrusion(face: int, cell: Cell, x: float, y: float, width: float, shade: float) -> void:
	var span := _protrusion_span(face, cell.protrusion_depth, x, width)
	var height := Tuning.TILE_H * 0.3
	var colour := SHELF.lerp(Color.WHITE, float(cell.protrusion_depth) * 0.06) * shade
	colour.a = 1.0
	draw_rect(Rect2(span.x, y - Tuning.TILE_H * 0.5, span.y - span.x, height), colour)


func _draw_solid_marks() -> void:
	if game == null or game.tower == null:
		return
	var base := origin()
	var half_rows := int(ceil(get_viewport_rect().size.y / (2.0 * Tuning.TILE_H))) + 1
	var first_row := maxi(0, int(floor(_camera_row)) - half_rows)
	var last_row := mini(game.tower.rows - 1, int(ceil(_camera_row)) + half_rows)

	for face in HexProjection.FACES:
		if not proj.is_face_visible(face):
			continue
		var width := proj.column_width(face)
		if width <= TILE_GAP:
			continue
		for local in proj.cols_per_face:
			var col := face * proj.cols_per_face + local
			var x := base.x + proj.column_center_x(col)
			for row in range(first_row, last_row + 1):
				var cell: Cell = game.tower.at(Vector2i(col, row))
				if cell == null:
					continue
				var centre_y := base.y + (float(row) - _camera_row) * Tuning.TILE_H
				var left := x - width * 0.5 + TILE_GAP * 0.5
				var right := x + width * 0.5 - TILE_GAP * 0.5
				if cell.casts_shadow():
					var span := _protrusion_span(face, cell.protrusion_depth, x, width)
					var top := centre_y - Tuning.TILE_H * 0.5 + TILE_GAP * 0.5
					_solid_marks.draw_line(Vector2(span.x, top), Vector2(span.y, top),
						SOLID_EDGE, 3.0)
				elif cell.blocked:
					_solid_marks.draw_rect(Rect2(
						left, centre_y - Tuning.TILE_H * 0.5 + TILE_GAP * 0.5,
						right - left, Tuning.TILE_H - TILE_GAP), RUBBLE_EDGE, false, 2.0)


func _tile_colour(cell: Cell) -> Color:
	if cell.blocked:
		return COLOR_BLOCKED
	return KIND_COLORS.get(cell.kind, KIND_COLORS[Cell.Kind.WALL])
