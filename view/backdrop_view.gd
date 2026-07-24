class_name BackdropView extends Node2D


const LAYERS: Array[Dictionary] = [
	{"path": "", "factor": 0.06, "tint": Color(0.08, 0.08, 0.15), "horizon": 0.22},
	{"path": "", "factor": 0.13, "tint": Color(0.11, 0.11, 0.19), "horizon": 0.44},
	{"path": "", "factor": 0.24, "tint": Color(0.14, 0.13, 0.23), "horizon": 0.63},
	{"path": "", "factor": 0.40, "tint": Color(0.17, 0.16, 0.27), "horizon": 0.81},
]
const PLACEHOLDER_BAND := 0.16
const PLACEHOLDER_PERIOD := 1.0

var tower_view: TowerView

var _textures: Array[Texture2D] = []


func _ready() -> void:
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	for layer in LAYERS:
		var path: String = layer["path"]
		_textures.append(load(path) if not path.is_empty() else null)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var view := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, view), TowerView.SKY)
	if tower_view == null:
		return
	for i in LAYERS.size():
		_draw_layer(i, view)


func _layer_offset(factor: float) -> Vector2:
	return Vector2(
		tower_view.proj.yaw * tower_view.proj.apothem(),
		-tower_view.camera_row() * Tuning.TILE_H) * factor


func _draw_layer(index: int, view: Vector2) -> void:
	var layer: Dictionary = LAYERS[index]
	var offset := _layer_offset(layer["factor"])
	var tex: Texture2D = _textures[index]
	if tex == null:
		_draw_placeholder(layer, offset, view)
		return
	var size := tex.get_size()
	var start := Vector2(fposmod(offset.x, size.x), fposmod(offset.y, size.y)) - size
	draw_texture_rect(tex, Rect2(start, view - start + size), true)


func _draw_placeholder(layer: Dictionary, offset: Vector2, view: Vector2) -> void:
	var period := view.y * PLACEHOLDER_PERIOD
	var top := fposmod(float(layer["horizon"]) * view.y + offset.y, period) - period
	var height := view.y * PLACEHOLDER_BAND
	while top < view.y:
		draw_rect(Rect2(0.0, top, view.x, height), layer["tint"])
		top += period
