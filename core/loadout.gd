class_name Loadout extends RefCounted


var owned: Dictionary = {}
var grace: int = 0
var ambush_ready: bool = false


func buy(upgrade: Upgrade) -> void:
	owned[upgrade.id] = owned.get(upgrade.id, 0) + 1
	if upgrade.id == Upgrade.Id.GRACE:
		grace = grace_max()


func count(upgrade_id: int) -> int:
	return owned.get(upgrade_id, 0)


func has(upgrade_id: int) -> bool:
	return count(upgrade_id) > 0


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
