class_name LetterView extends Node2D


const SPRITE_PATH := "res://assets/letters/letter.png"

const PAPER := Color(0.94, 0.90, 0.78)
const INK := Color(0.16, 0.12, 0.14)
const SEAL := Color(0.72, 0.16, 0.20)

const FLIGHT_SECS := 0.9
const FLIGHT_ROWS := 18.0
const FLIGHT_EASING := 2.2

var game: Game
var tower_view: TowerView

var _sprite: Texture2D
var _in_flight: Array[Dictionary] = []


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	if ResourceLoader.exists(SPRITE_PATH):
		_sprite = load(SPRITE_PATH)
	if game != null:
		game.letter_sent.connect(_on_letter_sent)


func _on_letter_sent(letter: Letter, _index: int, _turns_gained: int) -> void:
	_in_flight.append({"col": letter.pos.x, "row": float(letter.pos.y), "t": 0.0})


func _process(delta: float) -> void:
	for i in range(_in_flight.size() - 1, -1, -1):
		var flight: Dictionary = _in_flight[i]
		flight["t"] = flight["t"] + delta / FLIGHT_SECS
		if flight["t"] >= 1.0:
			_in_flight.remove_at(i)
	queue_redraw()


func _draw() -> void:
	if game == null or tower_view == null or game.tower == null:
		return
	for letter in game.letters:
		if letter.sent or not tower_view.is_cell_visible(letter.pos):
			continue
		_draw_letter(tower_view.cell_rect(letter.pos), 1.0)
	for flight in _in_flight:
		_draw_flight(flight)


func _draw_flight(flight: Dictionary) -> void:
	var col: int = flight["col"]
	var row: float = flight["row"]
	var t: float = clampf(flight["t"], 0.0, 1.0)
	var origin := Vector2i(col, int(row))
	if not tower_view.is_cell_visible(origin):
		return
	var fallen := pow(t, FLIGHT_EASING) * FLIGHT_ROWS
	var rect := tower_view.cell_rect(origin)
	rect.position.y += fallen * Tuning.TILE_H
	var scale := lerpf(1.0, 0.5, t)
	rect = Rect2(rect.get_center() - rect.size * scale * 0.5, rect.size * scale)
	_draw_letter(rect, 1.0 - smoothstep(0.5, 1.0, t))


func _draw_letter(cell: Rect2, alpha: float) -> void:
	if alpha <= 0.0:
		return
	if _sprite != null:
		_draw_sprite(cell, alpha)
		return
	var w := cell.size.x * 0.56
	var h := w * 0.68
	var rect := Rect2(cell.get_center() - Vector2(w, h) * 0.5, Vector2(w, h))
	var ink := Color(INK, INK.a * alpha)
	draw_rect(rect, Color(PAPER, PAPER.a * alpha))
	draw_rect(rect, ink, false, 2.0)
	var crease := rect.position + rect.size * Vector2(0.5, 0.52)
	draw_line(rect.position, crease, ink, 2.0)
	draw_line(Vector2(rect.end.x, rect.position.y), crease, ink, 2.0)
	draw_circle(crease, w * 0.1, Color(SEAL, SEAL.a * alpha))


func _draw_sprite(cell: Rect2, alpha: float) -> void:
	var size := _sprite.get_size()
	if size.x <= 0.0 or size.y <= 0.0:
		return
	var dest_w := cell.size.x
	var dest_h := dest_w * size.y / size.x
	var dest := Rect2(cell.position.x, cell.end.y - dest_h, dest_w, dest_h)
	_sprite.draw_rect(get_canvas_item(), dest, false, Color(1.0, 1.0, 1.0, alpha))
