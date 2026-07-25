class_name Loadout extends RefCounted


var owned: Dictionary = {}
var expires_at: Dictionary = {}
var grace: int = 0
var ambush_ready: bool = false

var _turn: int = 0


func buy(upgrade: Upgrade) -> void:
	owned[upgrade.id] = owned.get(upgrade.id, 0) + 1
	if upgrade.is_temporary():
		expires_at[upgrade.id] = _turn + upgrade.duration
	if upgrade.id == Upgrade.Id.GRACE:
		grace = grace_max()


func tick(p_turn: int) -> Array:
	_turn = p_turn
	var lapsed: Array = []
	for id: int in expires_at.keys():
		if p_turn < expires_at[id]:
			continue
		lapsed.append(id)
		expires_at.erase(id)
		owned.erase(id)
	if lapsed.has(Upgrade.Id.AMBUSH):
		ambush_ready = false
	return lapsed


func turns_left(upgrade_id: int) -> int:
	if not expires_at.has(upgrade_id):
		return 0
	return maxi(0, expires_at[upgrade_id] - _turn)


func count(upgrade_id: int) -> int:
	return owned.get(upgrade_id, 0)


func has(upgrade_id: int) -> bool:
	return count(upgrade_id) > 0


func gains_from(upgrade: Upgrade) -> bool:
	if upgrade.is_temporary():
		return true
	if upgrade.id == Upgrade.Id.GRACE:
		return grace_max() < Tuning.GRACE_CAP
	return true


func strength() -> int:
	return count(Upgrade.Id.STRENGTH) * Upgrade.of(Upgrade.Id.STRENGTH).magnitude


func grace_max() -> int:
	return mini(
		count(Upgrade.Id.GRACE) * Upgrade.of(Upgrade.Id.GRACE).magnitude,
		Tuning.GRACE_CAP)


func refill_grace() -> void:
	grace = grace_max()


func ambush_bonus() -> int:
	if not ambush_ready:
		return 0
	return count(Upgrade.Id.AMBUSH) * Upgrade.of(Upgrade.Id.AMBUSH).magnitude


func arm_ambush() -> void:
	ambush_ready = true


func break_stillness() -> void:
	ambush_ready = false


func spend_grace() -> bool:
	if grace <= 0:
		return false
	grace -= 1
	return true
