class_name ActorView extends Node2D


const BODY := Color(0.09, 0.04, 0.12)
const CLOAK := Color(0.42, 0.07, 0.14)
const OUTLINE := Color(0.85, 0.82, 0.95)
const EYES := Color(1.0, 0.35, 0.35)
const BURNING := Color(1.0, 0.55, 0.2)

const SPECIES_COLORS := {
	Species.Id.WINDOW_SWIPER: Color(0.62, 0.24, 0.55),
	Species.Id.CRAWLER: Color(0.36, 0.62, 0.32),
	Species.Id.GARGOYLE: Color(0.58, 0.58, 0.63),
	Species.Id.SHADE_LURKER: Color(0.28, 0.30, 0.68),
	Species.Id.SWARMLING: Color(0.78, 0.62, 0.24),
	Species.Id.LANTERN_GUARD: Color(0.94, 0.78, 0.36),
	Species.Id.STONEMASON: Color(0.50, 0.34, 0.22),
	Species.Id.NEST: Color(0.86, 0.44, 0.16),
}
const LANTERN_HALO := Color(1.0, 0.82, 0.42, 0.55)
const FROZEN := Color(0.82, 0.88, 1.0)
const TELEGRAPH := Color(1.0, 0.30, 0.25, 0.85)

var game: Game
var tower_view: TowerView


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if game == null or tower_view == null or game.tower == null:
		return
	for actor in game.actors:
		if not actor.is_player() and actor.is_winding_up():
			_draw_telegraph(actor)
	for actor in game.actors:
		if not tower_view.is_cell_visible(actor.pos):
			continue
		if actor.is_player():
			_draw_player(actor, tower_view.cell_rect(actor.pos))
		else:
			_draw_enemy(actor, tower_view.cell_rect(actor.pos))


func _draw_telegraph(enemy: Actor) -> void:
	if not tower_view.is_cell_visible(enemy.lunge_target):
		return
	var landing := tower_view.cell_rect(enemy.lunge_target)
	if tower_view.is_cell_visible(enemy.pos):
		draw_line(tower_view.cell_rect(enemy.pos).get_center(), landing.get_center(),
			TELEGRAPH, 3.0)
	draw_rect(landing.grow(-4.0), TELEGRAPH, false, 3.0)


func _draw_player(actor: Actor, rect: Rect2) -> void:
	var burning := game.light.state_at(actor.pos) == LightField.State.LIT
	var body := rect.grow_individual(-rect.size.x * 0.28, -rect.size.y * 0.2,
		-rect.size.x * 0.28, -rect.size.y * 0.12)

	var wing_y := rect.position.y + rect.size.y * 0.45
	draw_colored_polygon(PackedVector2Array([
		Vector2(rect.position.x, rect.end.y),
		Vector2(rect.position.x + rect.size.x * 0.5, wing_y),
		Vector2(rect.end.x, rect.end.y),
	]), BURNING if burning else CLOAK)

	draw_rect(body, BODY)
	draw_rect(body, OUTLINE if not burning else BURNING, false, 2.0)

	var eye := Vector2(maxf(2.0, rect.size.x * 0.09), maxf(2.0, rect.size.y * 0.06))
	var eye_y := rect.position.y + rect.size.y * 0.34
	draw_rect(Rect2(Vector2(rect.position.x + rect.size.x * 0.36, eye_y), eye), EYES)
	draw_rect(Rect2(Vector2(rect.position.x + rect.size.x * 0.55, eye_y), eye), EYES)

	_draw_health_pips(actor, rect)


func _draw_enemy(actor: Actor, rect: Rect2) -> void:
	var frozen := actor.species.light_rule == Species.LightRule.FREEZES_IN_LIGHT \
		and game.light.state_at(actor.pos) == LightField.State.LIT
	var tint: Color = SPECIES_COLORS.get(actor.species.id, Color.MAGENTA)
	if frozen:
		tint = tint.lerp(FROZEN, 0.7)

	if actor.species.id == Species.Id.LANTERN_GUARD:
		draw_rect(rect.grow(rect.size.x * 0.25), LANTERN_HALO, false, 3.0)

	var body := rect.grow_individual(-rect.size.x * 0.18, -rect.size.y * 0.22,
		-rect.size.x * 0.18, -rect.size.y * 0.18)
	draw_rect(body, tint)
	draw_rect(body, BODY, false, 2.0)

	if actor.is_winding_up():
		draw_rect(rect.grow(-2.0), TELEGRAPH, false, 2.0)

	var eye := Vector2(maxf(2.0, rect.size.x * 0.10), maxf(2.0, rect.size.y * 0.07))
	var eye_y := rect.position.y + rect.size.y * 0.36
	var eye_colour := BODY if frozen else EYES
	draw_rect(Rect2(Vector2(rect.position.x + rect.size.x * 0.32, eye_y), eye), eye_colour)
	draw_rect(Rect2(Vector2(rect.position.x + rect.size.x * 0.56, eye_y), eye), eye_colour)

	_draw_damage_notches(actor, rect)


func _draw_damage_notches(actor: Actor, rect: Rect2) -> void:
	if actor.hp >= actor.max_hp:
		return
	var lost := actor.max_hp - actor.hp
	var notch := Vector2(maxf(2.0, rect.size.x * 0.12), 3.0)
	var y := rect.position.y - 6.0
	for i in lost:
		draw_rect(Rect2(Vector2(rect.position.x + i * (notch.x + 2.0), y), notch),
			Color(0.9, 0.2, 0.25))


func _draw_health_pips(actor: Actor, rect: Rect2) -> void:
	var pip := Vector2(maxf(2.0, rect.size.x / float(actor.max_hp) - 2.0), 4.0)
	var y := rect.position.y - 10.0
	for i in actor.max_hp:
		var filled := i < actor.hp
		draw_rect(Rect2(Vector2(rect.position.x + i * (pip.x + 2.0), y), pip),
			Color(0.9, 0.2, 0.25) if filled else Color(0.2, 0.2, 0.25))
