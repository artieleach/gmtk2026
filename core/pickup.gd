class_name Pickup extends RefCounted


var pos: Vector2i
var upgrade_id: int
var taken: bool = false


static func create(p_pos: Vector2i, p_upgrade_id: int) -> Pickup:
	var pickup := Pickup.new()
	pickup.pos = p_pos
	pickup.upgrade_id = p_upgrade_id
	return pickup


func price() -> int:
	return Tuning.UPGRADE_PRICE
