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

const CREATURE_DIR := "res://assets/creatures/"
const MANIFEST_PATH := CREATURE_DIR + "manifest.json"

const CLIPS := {
	Species.Id.WINDOW_SWIPER: {"idle": "cat_idle", "swipe": ["cat_swipe_a", "cat_swipe_b"]},
	Species.Id.CRAWLER: {"idle": "silverfish_idle"},
	Species.Id.GARGOYLE: {"idle": "gargoyle_close", "open": "gargoyle_open"},
	Species.Id.SWARMLING: {"idle": "wasp_idle"},
}
const PLAYER_CLIPS := {"idle": "duck_flap"}

const SWIPE_SECS := 0.34

const MOVE_SECS := 0.12
const ATTACK_SECS := 0.26
const LURCH_BACK := 0.12
const LURCH_FWD := 0.32
const LURCH_WIND := 0.35

var game: Game
var tower_view: TowerView

var _clips: Dictionary = {}
var _clock: float = 0.0
var _strike: Dictionary = {}
var _paw: Dictionary = {}
var _move: Dictionary = {}
var _attack: Dictionary = {}
var _facing: Dictionary = {}


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_load_clips()
	if game != null:
		game.actor_moved.connect(_on_actor_moved)
		game.actor_attacked.connect(_on_actor_attacked)
		game.actor_died.connect(_on_actor_died)


func _load_clips() -> void:
	var file := FileAccess.open(MANIFEST_PATH, FileAccess.READ)
	if file == null:
		return
	var data: Variant = JSON.parse_string(file.get_as_text())
	if typeof(data) != TYPE_DICTIONARY:
		return
	for clip: String in data:
		var meta: Dictionary = data[clip]
		var tex: Texture2D = load(CREATURE_DIR + clip + ".png")
		if tex == null:
			continue
		_clips[clip] = {
			"tex": tex,
			"frames": int(meta["frames"]),
			"fw": float(meta["w"]),
			"fh": float(meta["h"]),
			"period": float(meta["ms"]) / 1000.0,
		}


func _on_actor_moved(actor: Actor, from: Vector2i, _to: Vector2i) -> void:
	_move[actor] = {"from": from, "at": _clock}


func _on_actor_attacked(attacker: Actor, target: Actor) -> void:
	var dx := game.tower.col_delta(attacker.pos.x, target.pos.x)
	if dx < 0:
		_facing[attacker] = -1
	elif dx > 0:
		_facing[attacker] = 1

	var dir := tower_view.cell_rect(target.pos).get_center() \
		- tower_view.cell_rect(attacker.pos).get_center()
	if dir.length() > 0.001:
		_attack[attacker] = {"dir": dir.normalized(), "at": _clock}

	var clips: Variant = CLIPS.get(attacker.species.id if attacker.species != null else -1)
	if typeof(clips) != TYPE_DICTIONARY or not clips.has("swipe"):
		return
	var paws: Array = clips["swipe"]
	var next := (int(_paw.get(attacker, -1)) + 1) % paws.size()
	_paw[attacker] = next
	_strike[attacker] = {"clip": paws[next], "at": _clock}


func _on_actor_died(actor: Actor) -> void:
	_strike.erase(actor)
	_paw.erase(actor)
	_move.erase(actor)
	_attack.erase(actor)
	_facing.erase(actor)


func _process(_delta: float) -> void:
	_clock += _delta
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
			_draw_player(actor, _actor_rect(actor))
		else:
			_draw_enemy(actor, _actor_rect(actor))


func _actor_rect(actor: Actor) -> Rect2:
	var rect := tower_view.cell_rect(actor.pos)
	var mv: Variant = _move.get(actor)
	if typeof(mv) == TYPE_DICTIONARY:
		var t := (_clock - float(mv["at"])) / MOVE_SECS
		if t < 1.0:
			rect = _lerp_rect(tower_view.cell_rect(mv["from"]), rect,
				smoothstep(0.0, 1.0, t))
		else:
			_move.erase(actor)
	var atk: Variant = _attack.get(actor)
	if typeof(atk) == TYPE_DICTIONARY:
		var ta := (_clock - float(atk["at"])) / ATTACK_SECS
		if ta < 1.0:
			rect.position += (atk["dir"] as Vector2) * (_lurch(ta) * rect.size.x)
		else:
			_attack.erase(actor)
	return rect


func _lerp_rect(a: Rect2, b: Rect2, t: float) -> Rect2:
	return Rect2(a.position.lerp(b.position, t), a.size.lerp(b.size, t))


func _lurch(t: float) -> float:
	if t < LURCH_WIND:
		return -LURCH_BACK * smoothstep(0.0, 1.0, t / LURCH_WIND)
	var b := (t - LURCH_WIND) / (1.0 - LURCH_WIND)
	return LURCH_FWD * sin(b * PI) - LURCH_BACK * (1.0 - b)


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
	if _has_clips(PLAYER_CLIPS):
		_draw_sprite(actor, rect, PLAYER_CLIPS["idle"], BURNING if burning else Color.WHITE)
		_draw_health_pips(actor, rect)
		return
	_draw_player_placeholder(actor, rect, burning)


func _draw_enemy(actor: Actor, rect: Rect2) -> void:
	var frozen := actor.species.light_rule == Species.LightRule.FREEZES_IN_LIGHT \
		and game.light.state_at(actor.pos) == LightField.State.LIT

	var clips: Variant = CLIPS.get(actor.species.id)
	if typeof(clips) == TYPE_DICTIONARY and _has_clips(clips):
		var clip := _enemy_clip(actor, clips)
		_draw_sprite(actor, rect, clip, FROZEN if frozen else Color.WHITE)
		if actor.is_winding_up():
			draw_rect(rect.grow(-2.0), TELEGRAPH, false, 2.0)
		_draw_damage_notches(actor, rect)
		return
	_draw_enemy_placeholder(actor, rect, frozen)


func _enemy_clip(actor: Actor, clips: Dictionary) -> String:
	if clips.has("open") and actor.is_winding_up():
		return clips["open"]
	var strike: Variant = _strike.get(actor)
	if typeof(strike) == TYPE_DICTIONARY and _clock - float(strike["at"]) < SWIPE_SECS:
		return strike["clip"]
	return clips["idle"]


func _has_clips(roles: Dictionary) -> bool:
	for role: String in roles:
		var value: Variant = roles[role]
		if value is Array:
			for clip_name: String in value:
				if not _clips.has(clip_name):
					return false
		elif not _clips.has(value):
			return false
	return true


func _draw_sprite(actor: Actor, rect: Rect2, clip: String, modulate: Color) -> void:
	var entry: Dictionary = _clips[clip]
	var frame := _frame_index(actor, clip, entry)
	var dest_h: float = rect.size.x * entry["fh"] / entry["fw"]
	var dest := Rect2(rect.position.x, rect.end.y - dest_h, rect.size.x, dest_h)
	var src := Rect2(frame * entry["fw"], 0.0, entry["fw"], entry["fh"])
	if int(_facing.get(actor, 1)) < 0:
		draw_set_transform(Vector2(dest.end.x, dest.position.y), 0.0, Vector2(-1.0, 1.0))
		draw_texture_rect_region(entry["tex"], Rect2(Vector2.ZERO, dest.size), src, modulate)
		draw_set_transform_matrix(Transform2D.IDENTITY)
	else:
		draw_texture_rect_region(entry["tex"], dest, src, modulate)


func _frame_index(actor: Actor, clip: String, entry: Dictionary) -> int:
	var frames: int = entry["frames"]
	var period: float = entry["period"]
	var strike: Variant = _strike.get(actor)
	if typeof(strike) == TYPE_DICTIONARY and strike["clip"] == clip:
		return mini(frames - 1, int((_clock - float(strike["at"])) / period))
	var phase := float(actor.get_instance_id() % 1000) * 0.001
	return int((_clock + phase) / period) % frames


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


func _draw_player_placeholder(actor: Actor, rect: Rect2, burning: bool) -> void:
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


func _draw_enemy_placeholder(actor: Actor, rect: Rect2, frozen: bool) -> void:
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
