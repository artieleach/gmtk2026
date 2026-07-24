class_name BackdropView extends Node2D


const BASE := Color(0.718, 0.114, 0.094)

const TOP_ANCHOR := 0.0

const LAYERS: Array[Dictionary] = [
	{"path": "res://assets/parralax/1Towers.png", "factor": 0.05, "head": 0.12798,
		"night": Color(0.30, 0.30, 0.42)},
	{"path": "res://assets/parralax/2Castle.png", "factor": 0.11, "head": 0.28963,
		"night": Color(0.36, 0.34, 0.44)},
	{"path": "res://assets/parralax/3Caths.png", "factor": 0.18, "head": 0.24326,
		"night": Color(0.42, 0.38, 0.46)},
	{"path": "res://assets/parralax/4town.png", "factor": 0.26, "head": 0.64850,
		"night": Color(0.50, 0.44, 0.50)},
]

var tower_view: TowerView

var _textures: Array[Texture2D] = []
var _floors: Array[Color] = []


func _ready() -> void:
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	for layer in LAYERS:
		var tex: Texture2D = load(layer["path"])
		_textures.append(tex)
		var image := tex.get_image()
		_floors.append(image.get_pixel(0, image.get_height() - 1))


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var view := get_viewport_rect().size
	var dawn := _dawn()
	draw_rect(Rect2(Vector2.ZERO, view), TowerView.SKY.lerp(BASE, dawn))
	if tower_view == null:
		return
	for i in LAYERS.size():
		_draw_layer(i, view, dawn)


func _dawn() -> float:
	if tower_view == null or tower_view.game == null:
		return 0.0
	var progress := tower_view.game.sun.progress(tower_view.sun_turn())
	return pow(progress, Tuning.SUN_RISE_EASING)


func _draw_layer(index: int, view: Vector2, dawn: float) -> void:
	var layer: Dictionary = LAYERS[index]
	var tex: Texture2D = _textures[index]
	var apothem := tower_view.proj.apothem()
	var width := TAU * apothem
	var height := width * float(tex.get_height()) / float(tex.get_width())
	var top := TOP_ANCHOR + float(layer["head"]) * width \
		- tower_view.camera_row() * Tuning.TILE_H * float(layer["factor"])
	var left := fposmod(tower_view.proj.yaw * apothem, width) - width
	var copies := ceilf((view.x - left) / width)
	var night: Color = layer["night"]
	var modulate := night.lerp(Color.WHITE, dawn)
	draw_texture_rect_region(tex,
		Rect2(left, top, width * copies, height),
		Rect2(0.0, 0.0, float(tex.get_width()) * copies, float(tex.get_height())),
		modulate)
	var floor_top := top + height
	if floor_top < view.y:
		var floor_colour: Color = _floors[index]
		draw_rect(Rect2(0.0, floor_top, view.x, view.y - floor_top),
			floor_colour * modulate)
