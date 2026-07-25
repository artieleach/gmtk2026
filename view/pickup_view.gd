class_name PickupView extends Node2D


const SPRITE_PATHS := {
	Upgrade.Id.STRENGTH: "res://assets/upgrades/strength.png",
	Upgrade.Id.GRACE: "res://assets/upgrades/grace.png",
	Upgrade.Id.JUMP: "res://assets/upgrades/plummet.png",
	Upgrade.Id.CARVE: "res://assets/upgrades/rend.png",
	Upgrade.Id.RAPPEL: "res://assets/upgrades/rappel.png",
	Upgrade.Id.SUREFOOT: "res://assets/upgrades/surefoot.png",
	Upgrade.Id.AMBUSH: "res://assets/upgrades/ambush.png",
}

const PLACEHOLDER_COLORS := {
	Upgrade.Id.STRENGTH: Color(0.86, 0.28, 0.24),
	Upgrade.Id.GRACE: Color(0.96, 0.84, 0.42),
	Upgrade.Id.JUMP: Color(0.40, 0.66, 0.90),
	Upgrade.Id.CARVE: Color(0.74, 0.50, 0.30),
	Upgrade.Id.RAPPEL: Color(0.44, 0.78, 0.62),
	Upgrade.Id.SUREFOOT: Color(0.60, 0.72, 0.44),
	Upgrade.Id.AMBUSH: Color(0.72, 0.42, 0.78),
}
const RUNE_OUTLINE := Color(0.06, 0.04, 0.09, 0.9)
const RUNE_LETTER := Color(0.10, 0.07, 0.12)

var game: Game
var tower_view: TowerView

var _sprites: Dictionary = {}


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	for id: int in SPRITE_PATHS:
		var path: String = SPRITE_PATHS[id]
		if ResourceLoader.exists(path):
			var tex: Texture2D = load(path)
			if tex != null:
				_sprites[id] = tex


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if game == null or tower_view == null or game.tower == null:
		return
	for pickup in game.pickups:
		if pickup.taken or not tower_view.is_cell_visible(pickup.pos):
			continue
		var rect := tower_view.cell_rect(pickup.pos)
		if _sprites.has(pickup.upgrade_id):
			_draw_sprite(_sprites[pickup.upgrade_id], rect)
		else:
			_draw_placeholder(pickup.upgrade_id, rect)


func _draw_sprite(tex: Texture2D, rect: Rect2) -> void:
	var size := tex.get_size()
	if size.x <= 0.0 or size.y <= 0.0:
		return
	var dest_w := rect.size.x
	var dest_h := dest_w * size.y / size.x
	var dest := Rect2(rect.position.x, rect.end.y - dest_h, dest_w, dest_h)
	tex.draw_rect(get_canvas_item(), dest, false)


func _draw_placeholder(upgrade_id: int, rect: Rect2) -> void:
	var color: Color = PLACEHOLDER_COLORS.get(upgrade_id, Color.MAGENTA)
	var c := rect.get_center()
	var r := minf(rect.size.x, rect.size.y) * 0.34
	var diamond := PackedVector2Array([
		c + Vector2(0, -r), c + Vector2(r, 0), c + Vector2(0, r), c + Vector2(-r, 0),
	])
	draw_colored_polygon(diamond, color)
	draw_polyline(diamond + PackedVector2Array([diamond[0]]), RUNE_OUTLINE, 2.0)

	var upgrade := Upgrade.of(upgrade_id)
	if upgrade == null:
		return
	var font := ThemeDB.fallback_font
	var font_size := int(r * 1.1)
	var letter := upgrade.display.substr(0, 1)
	var text_size := font.get_string_size(letter, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	draw_string(font, c + Vector2(-text_size.x * 0.5, text_size.y * 0.32), letter,
		HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, RUNE_LETTER)
