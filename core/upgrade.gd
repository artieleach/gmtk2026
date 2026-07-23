class_name Upgrade extends RefCounted


enum Id { STRENGTH, GRACE, JUMP, SHADE, TERROR, CARVE }

enum Kind {
	PASSIVE,
	ACTIVE,
}

var id: int
var display: String
var blurb: String
var kind: int
var price: int
var magnitude: int
var needs_direction: bool = false


static var _table: Dictionary = {}


static func of(upgrade_id: int) -> Upgrade:
	if _table.is_empty():
		_build_table()
	return _table.get(upgrade_id)


static func all_ids() -> Array:
	if _table.is_empty():
		_build_table()
	return _table.keys()


static func is_active(upgrade_id: int) -> bool:
	return of(upgrade_id).kind == Kind.ACTIVE


static func _make(id: int, display: String, blurb: String, kind: int, price: int, magnitude: int, needs_direction: bool = false) -> Upgrade:
	var u := Upgrade.new()
	u.id = id
	u.display = display
	u.blurb = blurb
	u.kind = kind
	u.price = price
	u.magnitude = magnitude
	u.needs_direction = needs_direction
	_table[id] = u
	return u


static func _build_table() -> void:
	_make(Id.STRENGTH, "Strength", "+1 damage per bite",
		Kind.PASSIVE, Tuning.UPGRADE_PRICE, 1)

	_make(Id.GRACE, "Grace", "+1 free step in sunlight, refilled by shade",
		Kind.PASSIVE, Tuning.UPGRADE_PRICE, 1)

	_make(Id.JUMP, "Leap", "Vault several tiles, over anything between",
		Kind.ACTIVE, Tuning.UPGRADE_PRICE, 3, true)

	_make(Id.SHADE, "Congeal", "Plant a clot that throws real shade",
		Kind.ACTIVE, Tuning.UPGRADE_PRICE, 2)

	_make(Id.TERROR, "Dread", "Nearby creatures flee",
		Kind.ACTIVE, Tuning.UPGRADE_PRICE, 2)

	_make(Id.CARVE, "Rend", "Tear away stone to open a way",
		Kind.ACTIVE, Tuning.UPGRADE_PRICE, 2, true)
