class_name Hud extends CanvasLayer


var game: Game

@onready var _status: Label = %Status
@onready var _banner: Label = %Banner
@onready var _kit: Label = %Kit
@onready var _toast: Label = %Toast
@onready var _toast_timer: Timer = %ToastTimer

const TOAST_SECS := 5.0


func _ready() -> void:
	if game == null:
		return
	game.turn_advanced.connect(_refresh.unbind(1))
	game.hp_changed.connect(_refresh.unbind(2))
	game.run_started.connect(_on_run_started)
	game.run_ended.connect(_on_run_ended)
	game.upgrade_picked.connect(_on_upgrade_picked)
	game.upgrade_lapsed.connect(_on_upgrade_lapsed)
	game.letter_sent.connect(_on_letter_sent)


func _on_run_started() -> void:
	_banner.visible = false
	_toast.visible = false
	_toast_timer.stop()
	_refresh()


func _on_upgrade_picked(pickup: Pickup, gained: bool) -> void:
	var upgrade := Upgrade.of(pickup.upgrade_id)
	if gained:
		_toast.text = "%s  %s" % [upgrade.display, upgrade.blurb]
		if upgrade.is_temporary():
			_toast.text += "  (%d turns)" % upgrade.duration
	else:
		_toast.text = "%s  already mastered" % upgrade.display
	_toast.visible = true
	_toast_timer.start(TOAST_SECS)


func _on_upgrade_lapsed(upgrade_id: int) -> void:
	_toast.text = "%s  spent" % Upgrade.of(upgrade_id).display
	_toast.visible = true
	_toast_timer.start(TOAST_SECS)


func _on_letter_sent(_letter: Letter, index: int, turns_gained: int) -> void:
	_toast.text = "%s  +%d turns" % [Letter.excuse(index), turns_gained]
	_toast.visible = true
	_toast_timer.start(TOAST_SECS)


func _on_toast_timeout() -> void:
	_toast.visible = false


func _on_run_ended(won: bool) -> void:
	_banner.text = "YOU WIN" if won else "GAME OVER"
	_banner.theme_type_variation = &"BannerWin" if won else &"BannerLose"
	_banner.visible = true


func _refresh() -> void:
	if game == null or game.player == null:
		return
	var remaining := game.sun.turns_until_daybreak(game.turn)
	_status.text = "HP %d/%d    depth %d/%d    letters %d/%d    %s    dawn %d%%    shadow %d deg" % [
		game.player.hp, game.player.max_hp,
		game.player.pos.y, game.tower.rows - 1,
		game.letters_sent(), game.letters.size(),
		"DAYBREAK no shade left" if remaining == 0 else "daybreak in %d" % remaining,
		int(roundf(game.sun.progress(game.turn) * 100.0)),
		int(roundf(game.sun.shadow_angle_deg(game.turn))),
	]
	_status.theme_type_variation = &"StatusUrgent" if remaining <= 25 else &"Status"
	_kit.text = _kit_text()


func _kit_text() -> String:
	var loadout := game.player.loadout
	if loadout == null:
		return ""
	var parts := PackedStringArray()
	if loadout.grace_max() > 0:
		parts.append("grace %d/%d" % [loadout.grace, loadout.grace_max()])
	if loadout.strength() > 0:
		parts.append("strength +%d" % loadout.strength())
	if loadout.has(Upgrade.Id.AMBUSH):
		var banked: int = loadout.count(Upgrade.Id.AMBUSH) \
			* Upgrade.of(Upgrade.Id.AMBUSH).magnitude
		parts.append("ambush +%d %ds%s" % [
			banked,
			loadout.turns_left(Upgrade.Id.AMBUSH),
			"  READY" if loadout.ambush_ready else "",
		])
	for id in [Upgrade.Id.JUMP, Upgrade.Id.CARVE, Upgrade.Id.RAPPEL, Upgrade.Id.SUREFOOT]:
		if loadout.has(id):
			parts.append("%s %dt" % [Upgrade.of(id).display.to_lower(), loadout.turns_left(id)])
	return "    ".join(parts)
