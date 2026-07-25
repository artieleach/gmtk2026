class_name CrownView extends Node2D


const PEAK_PATH := "res://assets/Top.png"
const FRAME_PATH := "res://assets/TowerBell frame.png"
const BELL_PATH := "res://assets/Bell.png"

const PEAK_FACES := 2

const BACK_SHADE := 0.32
const BELL_SHADE := 0.72
const PEAK_SHADE := 1.0

var tower_view: TowerView

var _peak: Texture2D
var _frame: Texture2D
var _bell: Texture2D
var _belfry_rows: int = 0
var _peak_rows: int = 0

var _axis: Node2D
var _near: Array[Node2D] = []
var _near_faces: Array[int] = []


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS

	_peak = load(PEAK_PATH)
	_frame = load(FRAME_PATH)
	_bell = load(BELL_PATH)
	_belfry_rows = TowerView.rows_of(_frame, Tuning.COLS_PER_FACE)
	_peak_rows = TowerView.rows_of(_peak, Tuning.COLS_PER_FACE * PEAK_FACES)

	_build_layers()
	visible = false


func _build_layers() -> void:
	var shader: Shader = load("res://view/barrier_light.gdshader")
	_axis = _add_layer(shader, "CrownAxis", _draw_axis)
	for i in 3:
		var slot := i
		_near.append(_add_layer(shader, "CrownFace%d" % i, func() -> void: _draw_near(slot)))
		_near_faces.append(-1)


func _add_layer(shader: Shader, layer_name: String, on_draw: Callable) -> Node2D:
	var layer := Node2D.new()
	layer.name = layer_name
	var material := ShaderMaterial.new()
	material.shader = shader
	layer.material = material
	layer.draw.connect(on_draw)
	add_child(layer)
	return layer


func crown_top_row() -> float:
	return -0.5 - float(maxi(_belfry_rows, _peak_rows))


func _process(_delta: float) -> void:
	if tower_view == null or not tower_view.light_ready():
		visible = false
		return
	if tower_view.row_top_y(0.0) < 0.0:
		visible = false
		return
	visible = true
	_update_layers()
	_axis.queue_redraw()
	for layer in _near:
		layer.queue_redraw()


func _update_layers() -> void:
	var shared := tower_view.light_uniforms()
	var top_row := crown_top_row()

	tower_view.apply_uniforms(_axis.material, shared)
	tower_view.apply_uniforms(_axis.material, tower_view.crown_light_uniforms(top_row))

	var slot := 0
	for face in HexProjection.FACES:
		if not tower_view.proj.is_face_visible(face) or slot >= _near.size():
			continue
		var per_face := tower_view.face_light_uniforms(face)
		if per_face.is_empty():
			continue
		per_face["top_row"] = top_row
		tower_view.apply_uniforms(_near[slot].material, shared)
		tower_view.apply_uniforms(_near[slot].material, per_face)
		_near_faces[slot] = face
		slot += 1
	for i in range(slot, _near.size()):
		_near_faces[i] = -1


func _frame_rect(face: int) -> Rect2:
	var cpf := Tuning.COLS_PER_FACE
	var head := tower_view.cell_rect(Vector2i(face * cpf, -_belfry_rows))
	var tail := tower_view.cell_rect(Vector2i(face * cpf + cpf - 1, -1))
	return Rect2(head.position, tail.end - head.position).abs()


func _bell_rect() -> Rect2:
	var width := Tuning.RADIUS
	return Rect2(
		tower_view.origin().x - width * 0.5,
		tower_view.row_top_y(-float(_belfry_rows)),
		width, float(_belfry_rows) * Tuning.TILE_H)


func _peak_rect() -> Rect2:
	var width := Tuning.RADIUS * float(PEAK_FACES)
	return Rect2(
		tower_view.origin().x - width * 0.5,
		tower_view.row_top_y(-float(_peak_rows)),
		width, float(_peak_rows) * Tuning.TILE_H)


func _draw_axis() -> void:
	_axis.draw_texture_rect(_peak, _peak_rect(), false, Color(PEAK_SHADE, PEAK_SHADE, PEAK_SHADE))
	for face in HexProjection.FACES:
		if tower_view.proj.face_facing(face) <= 0.0:
			_draw_frame(_axis, face, BACK_SHADE)
	_axis.draw_texture_rect(_bell, _bell_rect(), false, Color(BELL_SHADE, BELL_SHADE, BELL_SHADE))


func _draw_near(slot: int) -> void:
	var face: int = _near_faces[slot]
	if face >= 0:
		_draw_frame(_near[slot], face, 1.0)


func _draw_frame(layer: Node2D, face: int, extra: float) -> void:
	var rect := _frame_rect(face)
	if rect.size.x <= TowerView.TILE_GAP:
		return
	var shade := lerpf(TowerView.EDGE_SHADE, 1.0,
		absf(tower_view.proj.face_facing(face))) * extra
	layer.draw_texture_rect(_frame, rect, false, Color(shade, shade, shade))
