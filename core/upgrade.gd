class_name Upgrade extends RefCounted


enum Id { STRENGTH, GRACE, JUMP, CARVE, RAPPEL, SUREFOOT, AMBUSH }

enum Kind {
	PASSIVE,
}

var id: int
var display: String
var blurb: String
var kind: int
var price: int
var magnitude: int


static var _table: Dictionary = {}


static func of(upgrade_id: int) -> Upgrade:
	if _table.is_empty():
		_build_table()
	return _table.get(upgrade_id)


static func all_ids() -> Array:
	if _table.is_empty():
		_build_table()
	return _table.keys()


static func _make(id: int, display: String, blurb: String, kind: int, price: int, magnitude: int) -> Upgrade:
	var u := Upgrade.new()
	u.id = id
	u.display = display
	u.blurb = blurb
	u.kind = kind
	u.price = price
	u.magnitude = magnitude
	_table[id] = u
	return u


static func _build_table() -> void:
	_make(Id.STRENGTH, "Strength", "+1 damage per bite",
		Kind.PASSIVE, Tuning.UPGRADE_PRICE, 1)

	_make(Id.GRACE, "Grace", "+1 free step in sunlight, refilled by shade",
		Kind.PASSIVE, Tuning.UPGRADE_PRICE, 1)

	_make(Id.JUMP, "Plummet", "Drop straight down, stopped only by walls",
		Kind.PASSIVE, Tuning.UPGRADE_PRICE, 0)

	_make(Id.CARVE, "Rend", "Smash the stone you climb into",
		Kind.PASSIVE, Tuning.UPGRADE_PRICE, 0)

	_make(Id.RAPPEL, "Rappel", "Slide down a rib you cannot step past",
		Kind.PASSIVE, Tuning.UPGRADE_PRICE, 0)

	_make(Id.SUREFOOT, "Surefoot", "Haul yourself up over an overhang",
		Kind.PASSIVE, Tuning.UPGRADE_PRICE, 0)

	_make(Id.AMBUSH, "Ambush", "Hold still, then strike harder",
		Kind.PASSIVE, Tuning.UPGRADE_PRICE, 2)
