class_name Actor extends RefCounted


enum Kind { PLAYER, ENEMY }

var pos: Vector2i = Vector2i.ZERO
var hp: int = Tuning.MAX_HP
var max_hp: int = Tuning.MAX_HP
var kind: int = Kind.PLAYER
var species: Species = null
var loadout: Loadout = null
var leash: int = 0

var next_action_turn: int = 0
var windup_turns: int = 0
var lunge_target: Vector2i = Vector2i.ZERO
var anchor: Vector2i = Vector2i.ZERO
var feared_until_turn: int = 0
var patrol_dir: Vector2i = Vector2i(1, 0)


static func create_enemy(species_id: int, pos: Vector2i) -> Actor:
	var actor := Actor.new()
	var s := Species.of(species_id)
	actor.kind = Kind.ENEMY
	actor.species = s
	actor.max_hp = s.max_hp
	actor.hp = s.max_hp
	actor.pos = pos
	actor.anchor = pos
	return actor


func is_alive() -> bool:
	return hp > 0


func is_player() -> bool:
	return kind == Kind.PLAYER


func is_winding_up() -> bool:
	return windup_turns > 0


func blood() -> int:
	return species.blood if species != null else 0
