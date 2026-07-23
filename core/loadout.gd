class_name Loadout extends RefCounted


var owned: Dictionary = {}
var charges: Dictionary = {}
var grace: int = 0


func buy(upgrade: Upgrade) -> void:
	owned[upgrade.id] = owned.get(upgrade.id, 0) + 1
	if upgrade.kind == Upgrade.Kind.ACTIVE:
		charges[upgrade.id] = charges.get(upgrade.id, 0) + upgrade.magnitude
	elif upgrade.id == Upgrade.Id.GRACE:
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


func spend_grace() -> bool:
	if grace <= 0:
		return false
	grace -= 1
	return true


func charges_of(upgrade_id: int) -> int:
	return charges.get(upgrade_id, 0)


func can_use(upgrade_id: int) -> bool:
	return charges_of(upgrade_id) > 0


func spend_charge(upgrade_id: int) -> bool:
	if not can_use(upgrade_id):
		return false
	charges[upgrade_id] -= 1
	return true
