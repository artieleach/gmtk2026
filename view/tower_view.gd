class_name TowerView extends Node2D


const SKY := Color(0.05, 0.05, 0.10)

const KIND_COLORS := {
	Cell.Kind.WALL: Color(0.44, 0.42, 0.47),
	Cell.Kind.BRICK: Color(0.38, 0.36, 0.41),
	Cell.Kind.LEDGE: Color(0.56, 0.53, 0.57),
	Cell.Kind.PILASTER: Color(0.52, 0.54, 0.59),
	Cell.Kind.WINDOW: Color(0.13, 0.11, 0.17),
	Cell.Kind.RUBBLE: Color(0.24, 0.22, 0.26),
	Cell.Kind.ALTAR: Color(0.62, 0.16, 0.22),
}
const COLOR_BLOCKED := Color(0.24, 0.22, 0.26)

const LIGHT_LIT := Color(1.00, 0.90, 0.60, 0.62)
const LIGHT_SHADED := Color(0.19, 0.19, 0.35, 0.74)
const LIGHT_DARK := Color(0.05, 0.06, 0.12, 0.74)
const LIGHT_FRONT_LINE := Color(1.0, 0.88, 0.50, 0.90)
const LIGHT_LANTERN := Color(1.00, 0.72, 0.34, 0.66)

const EDGE_SHADE := 0.5
const TILE_GAP := 2.0

const WINDOW_TEXTURE_PATHS := {
	Vector2i(1, 2): {
		"closed": "res://assets/1x2 window closed.png",
		"open": "res://assets/1x2 window open.png",
	},
	Vector2i(3, 5): {
		"closed": "res://assets/5x3 Window close.png",
		"open": "res://assets/5x3 Window open.png",
	},
}

const LEVEL_PATHS: Array[String] = [
	"res://assets/level1.png",
	"res://assets/level2.png",
	"res://assets/level3.png",
	"res://assets/level4.png",
]
const LEVEL_ART_VALUE := 0.55
const LEVEL_STRENGTH := 1.0

var game: Game
var proj := HexProjection.new()

var _camera_row: float = 0.0
var _sun_turn: float = 0.0
var _yaw_target: float = 0.0
var _face: int = 0
var _bars_texture: ImageTexture
var _bars_image: Image
var _light_rects: Array[ColorRect] = []
var _window_textures: Dictionary = {}
var _level_textures: Array[Texture2D] = []
var _level_rows: int = 0


func _ready() -> void:
	for size: Vector2i in WINDOW_TEXTURE_PATHS:
		var paths: Dictionary = WINDOW_TEXTURE_PATHS[size]
		_window_textures[size] = {
			"open": load(paths["open"]),
			"closed": load(paths["closed"]),
		}
	for path in LEVEL_PATHS:
		_level_textures.append(load(path))
	if not _level_textures.is_empty():
		var level: Texture2D = _level_textures[0]
		_level_rows = int(round(float(level.get_height()) * float(Tuning.COLS_PER_FACE)
			/ float(level.get_width())))

	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS

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
		rect.material = material
		add_child(rect)
		_light_rects.append(rect)


func _on_run_started() -> void:
	if game == null or game.player == null:
		return
	_face = game.tower.face_of(game.player.pos.x)
	_yaw_target = HexProjection.yaw_for_face(_face)
	proj.yaw = _yaw_target
	_camera_row = float(game.player.pos.y)
	_sun_turn = float(game.turn)
	_build_bars_texture()


func _build_bars_texture() -> void:
	var tower := game.tower
	var bytes := PackedByteArray()
	bytes.resize(tower.cols * tower.rows)
	for i in tower.cells.size():
		bytes[i] = tower.cells[i].bars
	_bars_image = Image.create_from_data(tower.cols, tower.rows, false, Image.FORMAT_R8, bytes)
	_bars_texture = ImageTexture.create_from_image(_bars_image)


func _on_tower_changed(pos: Vector2i) -> void:
	if _bars_image == null or _bars_texture == null:
		return
	var bars := float(game.tower.at(pos).bars) / 255.0
	_bars_image.set_pixel(pos.x, pos.y, Color(bars, 0.0, 0.0))
	_bars_texture.update(_bars_image)


func _process(delta: float) -> void:
	if game != null:
		_ease_sun(delta)
	if game != null and game.player != null:
		_track_player(delta)
	_update_light_rects()
	queue_redraw()


func _ease_sun(delta: float) -> void:
	var follow := 1.0 - exp(-Tuning.SUN_FOLLOW_SPEED * delta)
	_sun_turn = lerpf(_sun_turn, float(game.turn), follow)


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


func camera_row() -> float:
	return _camera_row


func sun_turn() -> float:
	return _sun_turn


func cell_rect(pos: Vector2i) -> Rect2:
	var col := game.tower.wrap_col(pos.x)
	var width := proj.column_width(proj.face_of(col))
	var centre := origin() + Vector2(
		proj.column_center_x(col),
		(float(pos.y) - _camera_row) * Tuning.TILE_H)
	return Rect2(centre - Vector2(width, Tuning.TILE_H) * 0.5, Vector2(width, Tuning.TILE_H))


func is_cell_visible(pos: Vector2i) -> bool:
	return proj.is_face_visible(proj.face_of(game.tower.wrap_col(pos.x)))


func cell_shade(pos: Vector2i) -> float:
	return lerpf(EDGE_SHADE, 1.0,
		proj.face_facing(proj.face_of(game.tower.wrap_col(pos.x))))


func _visible_lanterns() -> Array:
	var packed: Array = []
	for pos: Vector2i in game.lantern_positions():
		packed.append(Vector4(pos.x, pos.y, 0.0, Tuning.LANTERN_RADIUS))
	return packed


func light_uniforms() -> Dictionary:
	var lanterns := _visible_lanterns()
	var uniforms := {
		"bars_tex": _bars_texture,
		"grid_size": Vector2(game.tower.cols, game.tower.rows),
		"front_row": game.sun.front_row(_sun_turn),
		"shadow_offset": game.sun.shadow_offset(_sun_turn),
		"casts_shadows": game.sun.casts_shadows(_sun_turn),
		"lantern_count": lanterns.size(),
		"lantern_height": Tuning.LANTERN_HEIGHT,
		"lit_color": LIGHT_LIT,
		"lantern_color": LIGHT_LANTERN,
		"shaded_color": LIGHT_SHADED,
		"dark_color": LIGHT_DARK,
		"front_line_color": LIGHT_FRONT_LINE,
	}
	if not lanterns.is_empty():
		uniforms["lanterns"] = lanterns
	return uniforms


func face_light_uniforms(face: int) -> Dictionary:
	var cpf := proj.cols_per_face
	var base := origin()
	var half_width := proj.column_width(face) * 0.5
	var left := base.x + proj.column_center_x(face * cpf) - half_width
	var right := base.x + proj.column_center_x(face * cpf + cpf - 1) + half_width
	if right - left < 1.0:
		return {}

	var viewport := get_viewport_rect().size
	var v_top := _camera_row - base.y / Tuning.TILE_H
	var v_bottom := _camera_row + (viewport.y - base.y) / Tuning.TILE_H
	return {
		"wall_min": Vector2(float(face * cpf) - 0.5, v_top),
		"wall_max": Vector2(float(face * cpf + cpf) - 0.5, v_bottom),
		"face_shade": lerpf(EDGE_SHADE, 1.0, proj.face_facing(face)),
		"screen_x_span": Vector2(left, right) / viewport.x,
	}


func light_ready() -> bool:
	return game != null and game.tower != null and _bars_texture != null


func apply_uniforms(material: ShaderMaterial, uniforms: Dictionary) -> void:
	for key: String in uniforms:
		material.set_shader_parameter(key, uniforms[key])


func _update_light_rects() -> void:
	if not light_ready():
		return
	var viewport := get_viewport_rect().size
	var shared := light_uniforms()

	var slot := 0
	for face in HexProjection.FACES:
		if not proj.is_face_visible(face) or slot >= _light_rects.size():
			continue
		var per_face := face_light_uniforms(face)
		if per_face.is_empty():
			continue

		var span: Vector2 = per_face["screen_x_span"] * viewport.x
		var rect := _light_rects[slot]
		rect.visible = true
		rect.position = Vector2(span.x, 0.0)
		rect.size = Vector2(span.y - span.x, viewport.y)
		apply_uniforms(rect.material, shared)
		apply_uniforms(rect.material, per_face)
		slot += 1

	for i in range(slot, _light_rects.size()):
		_light_rects[i].visible = false


func _draw() -> void:
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

	_draw_windows(first_row, last_row)


func _draw_windows(first_row: int, last_row: int) -> void:
	for window in game.tower.windows:
		var origin: Vector2i = window["origin"]
		var size: Vector2i = window["size"]
		if origin.y + size.y - 1 < first_row or origin.y > last_row:
			continue
		if not is_cell_visible(origin):
			continue
		var art: Dictionary = _window_textures.get(size, {})
		var tex: Texture2D = art.get("open" if window["open"] else "closed")
		if tex == null:
			continue
		var top_left := cell_rect(origin)
		var bottom_right := cell_rect(origin + size - Vector2i.ONE)
		draw_texture_rect(tex, Rect2(top_left.position, bottom_right.end - top_left.position), false)


func _draw_face(face: int, base: Vector2, first_row: int, last_row: int) -> void:
	var shade := lerpf(EDGE_SHADE, 1.0, proj.face_facing(face))
	var width := proj.column_width(face)
	if width <= TILE_GAP:
		return

	for local in proj.cols_per_face:
		var col := face * proj.cols_per_face + local
		var x := base.x + proj.column_center_x(col)
		for row in range(first_row, last_row + 1):
			var pos := Vector2i(col, row)
			var cell: Cell = game.tower.at(pos)
			if cell == null:
				continue
			var y := base.y + (float(row) - _camera_row) * Tuning.TILE_H
			var colour := _tile_colour(cell) * shade
			colour.a = 1.0
			var tile := Rect2(
				x - width * 0.5 + TILE_GAP * 0.5,
				y - Tuning.TILE_H * 0.5 + TILE_GAP * 0.5,
				width - TILE_GAP,
				Tuning.TILE_H - TILE_GAP)
			draw_rect(tile, colour)
			_draw_level(cell, pos, tile, colour)


func _draw_level(cell: Cell, pos: Vector2i, tile: Rect2, tile_colour: Color) -> void:
	if _level_rows <= 0 or cell.blocked:
		return
	if cell.kind != Cell.Kind.WALL and cell.kind != Cell.Kind.BRICK:
		return
	var band := Tuning.LEVEL_REPEATS * _level_rows
	var tex: Texture2D = _level_textures[(pos.y / band) % _level_textures.size()]
	var cell_px := float(tex.get_width()) / float(Tuning.COLS_PER_FACE)
	var region := Rect2(
		Vector2(float(pos.x % Tuning.COLS_PER_FACE), float(pos.y % _level_rows)) * cell_px,
		Vector2(cell_px, cell_px))
	var colour := tile_colour / LEVEL_ART_VALUE
	colour.a = LEVEL_STRENGTH
	draw_texture_rect_region(tex, tile, region, colour)


func _tile_colour(cell: Cell) -> Color:
	if cell.blocked:
		return COLOR_BLOCKED
	return KIND_COLORS.get(cell.kind, KIND_COLORS[Cell.Kind.WALL])
