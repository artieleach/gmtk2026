class_name Upgrade extends RefCounted


enum Id { STRENGTH, GRACE, JUMP, CARVE, RAPPEL, SUREFOOT, AMBUSH }

var id: int
var display: String
var blurb: String
var price: int
var magnitude: int
var duration: int


func is_temporary() -> bool:
	return duration > 0


static var _table: Dictionary = {}


static func of(upgrade_id: int) -> Upgrade:
	if _table.is_empty():
		_build_table()
	return _table.get(upgrade_id)


static func all_ids() -> Array:
	if _table.is_empty():
		_build_table()
	return _table.keys()


static func _make(id: int, display: String, blurb: String, price: int,
		magnitude: int, duration: int = 0) -> Upgrade:
	var u := Upgrade.new()
	u.id = id
	u.display = display
	u.blurb = blurb
	u.price = price
	u.magnitude = magnitude
	u.duration = duration
	_table[id] = u
	return u


static func _build_table() -> void:
	_make(Id.STRENGTH, "Strength", "+1 damage per bite",
		Tuning.UPGRADE_PRICE, 1)

	_make(Id.GRACE, "Grace", "+1 free step in sunlight, refilled by shade",
		Tuning.UPGRADE_PRICE, 1)

	_make(Id.JUMP, "Plummet", "Drop straight down, stopped only by walls",
		Tuning.UPGRADE_PRICE, 0, Tuning.POWER_DURATION_TURNS)

	_make(Id.CARVE, "Rend", "Smash the stone you climb into",
		Tuning.UPGRADE_PRICE, 0, Tuning.POWER_DURATION_TURNS)

	_make(Id.RAPPEL, "Rappel", "Slide down a rib you cannot step past",
		Tuning.UPGRADE_PRICE, 0, Tuning.POWER_DURATION_TURNS)

	_make(Id.SUREFOOT, "Surefoot", "Haul yourself up over an overhang",
		Tuning.UPGRADE_PRICE, 0, Tuning.POWER_DURATION_TURNS)

	_make(Id.AMBUSH, "Ambush", "Hold still, then strike harder",
		Tuning.UPGRADE_PRICE, 2, Tuning.POWER_DURATION_TURNS)
