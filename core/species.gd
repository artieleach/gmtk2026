class_name Species extends RefCounted


enum Id {
	WINDOW_SWIPER, CRAWLER, GARGOYLE, SHADE_LURKER, SWARMLING,
	LANTERN_GUARD, STONEMASON, NEST,
}

enum LightRule {
	IGNORES,
	FREEZES_IN_LIGHT,
	SHADE_ONLY,
}

var id: int
var display: String
var max_hp: int
var damage: int
var blood: int
var move_period: int
var lunge_range: int
var light_rule: int
var brain_id: StringName


static var _table: Dictionary = {}


static func of(species_id: int) -> Species:
	if _table.is_empty():
		_build_table()
	return _table.get(species_id)


static func all_ids() -> Array:
	if _table.is_empty():
		_build_table()
	return _table.keys()


static func _make(id: int, display: String, max_hp: int, damage: int, blood: int,
		move_period: int, lunge_range: int, light_rule: int, brain_id: StringName) -> Species:
	var s := Species.new()
	s.id = id
	s.display = display
	s.max_hp = max_hp
	s.damage = damage
	s.blood = blood
	s.move_period = move_period
	s.lunge_range = lunge_range
	s.light_rule = light_rule
	s.brain_id = brain_id
	_table[id] = s
	return s


static func _build_table() -> void:

	_make(Id.WINDOW_SWIPER, "swiper", 3, 2, 3, 1, 0, LightRule.IGNORES, &"sentry")

	_make(Id.CRAWLER, "crawler", 3, 2, 3, 2, 0, LightRule.IGNORES, &"chaser")

	_make(Id.GARGOYLE, "gargoyle", 6, 4, 0, 1, 3, LightRule.FREEZES_IN_LIGHT, &"lunger")

	_make(Id.SHADE_LURKER, "lurker", 2, 3, 3, 1, 0, LightRule.SHADE_ONLY, &"stalker")

	_make(Id.SWARMLING, "swarmling", 1, 1, 2, 1, 0, LightRule.IGNORES, &"chaser")

	_make(Id.NEST, "nest", 6, 0, 6, Tuning.NEST_SPAWN_PERIOD, 0, LightRule.IGNORES, &"hive")

	_make(Id.LANTERN_GUARD, "guard", 4, 2, 4, 2, 0, LightRule.IGNORES, &"patroller")

	_make(Id.STONEMASON, "mason", 4, 2, 4, 2, 0, LightRule.IGNORES, &"mason")
