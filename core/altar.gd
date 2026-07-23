class_name Altar extends RefCounted


var pos: Vector2i
var offers: Array[int] = []
var spent: bool = false


static func create(p_pos: Vector2i, p_offers: Array[int]) -> Altar:
	var altar := Altar.new()
	altar.pos = p_pos
	altar.offers = p_offers
	return altar


func price() -> int:
	return Tuning.UPGRADE_PRICE
