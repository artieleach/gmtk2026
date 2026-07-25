class_name BackdropView extends Node2D


const BASE := Color(0.718, 0.114, 0.094)

const TOP_ANCHOR := 0.0

const LAYERS: Array[Dictionary] = [
	{"path": "res://assets/parralax/1Towers.res", "factor": 0.05, "head": 0.12798,
		"night": Color(0.30, 0.30, 0.42)},
	{"path": "res://assets/parralax/2Castle.res", "factor": 0.11, "head": 0.28963,
		"night": Color(0.36, 0.34, 0.44)},
	{"path": "res://assets/parralax/3Caths.res", "factor": 0.18, "head": 0.24326,
		"night": Color(0.42, 0.38, 0.46)},
	{"path": "res://assets/parralax/4town.res", "factor": 0.26, "head": 0.64850,
		"night": Color(0.50, 0.44, 0.50)},
]

var tower_view: TowerView

var _shapes: Array[BackdropShapes] = []


func _ready() -> void:
	for layer in LAYERS:
		var path: String = layer["path"]
		if not ResourceLoader.exists(path):
			push_warning("BackdropView: %s not baked  run tools/svg_to_polys.gd" % path)
			_shapes.append(null)
			continue
		_shapes.append(load(path))


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var view := get_viewport_rect().size
	var dawn := _dawn()
	draw_rect(Rect2(Vector2.ZERO, view), TowerView.SKY.lerp(BASE, dawn))
	if tower_view == null:
		return
	for i in LAYERS.size():
		if _shapes[i] != null:
			_draw_layer(i, view, dawn)


func _dawn() -> float:
	if tower_view == null or tower_view.game == null:
		return 0.0
	var progress := tower_view.game.sun.progress(tower_view.sun_turn())
	return pow(progress, Tuning.SUN_RISE_EASING)


func _draw_layer(index: int, view: Vector2, dawn: float) -> void:
	var layer: Dictionary = LAYERS[index]
	var shapes: BackdropShapes = _shapes[index]
	var width := TAU * tower_view.proj.apothem()
	var scale := width / shapes.canvas.x
	var top := TOP_ANCHOR + float(layer["head"]) * width \
		- tower_view.camera_row() * Tuning.TILE_H * float(layer["factor"])
	var left := fposmod(tower_view.proj.yaw * tower_view.proj.apothem(), width) - width
	var copies := int(ceil((view.x - left) / width))
	var night: Color = layer["night"]
	var modulate := night.lerp(Color.WHITE, dawn)
	for copy in copies:
		draw_mesh(shapes.mesh, null, Transform2D(0.0, Vector2(scale, scale), 0.0,
			Vector2(left + float(copy) * width, top)), modulate)
	var floor_top := top + shapes.canvas.y * scale
	if floor_top < view.y:
		draw_rect(Rect2(0.0, floor_top, view.x, view.y - floor_top),
			shapes.floor_color * modulate)
