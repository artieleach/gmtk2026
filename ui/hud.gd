class_name Hud extends CanvasLayer


var game: Game

var _status: Label
var _banner: Label
var _kit: Label
var _altar: Label
var _altar_backdrop: ColorRect


func _ready() -> void:
	_status = _make_label(HORIZONTAL_ALIGNMENT_LEFT)
	_status.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_status.offset_left = 24.0
	_status.offset_top = 20.0
	_status.offset_right = -24.0
	_status.add_theme_font_size_override("font_size", 28)

	_banner = _make_label(HORIZONTAL_ALIGNMENT_CENTER)
	_banner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_banner.add_theme_font_size_override("font_size", 64)
	_banner.visible = false

	_kit = _make_label(HORIZONTAL_ALIGNMENT_LEFT)
	_kit.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_kit.offset_left = 24.0
	_kit.offset_top = 56.0
	_kit.offset_right = -24.0
	_kit.add_theme_font_size_override("font_size", 22)

	_altar_backdrop = ColorRect.new()
	_altar_backdrop.color = Color(0.04, 0.03, 0.06, 0.82)
	_altar_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_altar_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_altar_backdrop.visible = false
	add_child(_altar_backdrop)

	_altar = _make_label(HORIZONTAL_ALIGNMENT_CENTER)
	_altar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_altar.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_altar.add_theme_font_size_override("font_size", 34)
	_altar.add_theme_color_override("font_color", Color(1.0, 0.82, 0.72))
	_altar.visible = false

	if game == null:
		return
	game.turn_advanced.connect(_refresh.unbind(1))
	game.hp_changed.connect(_refresh.unbind(2))
	game.run_started.connect(_on_run_started)
	game.run_ended.connect(_on_run_ended)
	game.altar_opened.connect(_on_altar_opened)
	game.altar_closed.connect(_on_altar_closed)


func _make_label(align: int) -> Label:
	var label := Label.new()
	label.horizontal_alignment = align
	label.add_theme_color_override("font_color", Color(0.92, 0.90, 0.82))
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	label.add_theme_constant_override("shadow_offset_y", 2)
	add_child(label)
	return label


func _on_run_started() -> void:
	_banner.visible = false
	_altar.visible = false
	_altar_backdrop.visible = false
	_refresh()


func _on_altar_opened(altar: Altar) -> void:
	var lines := PackedStringArray(["AN ALTAR  %d blood" % altar.price()])
	for i in altar.offers.size():
		var upgrade := Upgrade.of(altar.offers[i])
		lines.append("%d.  %s  %s" % [i + 1, upgrade.display, upgrade.blurb])
	lines.append("" if game.can_afford(altar) else "not enough blood")
	lines.append("Esc to walk away")
	_altar.text = "\n".join(lines)
	_altar.visible = true
	_altar_backdrop.visible = true


func _on_altar_closed() -> void:
	_altar.visible = false
	_altar_backdrop.visible = false
	_refresh()


func _on_run_ended(won: bool) -> void:
	_banner.text = "YOU WIN" if won else "GAME OVER"
	_banner.add_theme_color_override("font_color",
		Color(0.7, 0.9, 1.0) if won else Color(1.0, 0.6, 0.35))
	_banner.visible = true


func _refresh() -> void:
	if game == null or game.player == null:
		return
	var remaining := game.sun.turns_until_daybreak(game.turn)
	_status.text = "HP %d/%d    depth %d/%d    %s    dawn %d%%    shadow %d deg" % [
		game.player.hp, game.player.max_hp,
		game.player.pos.y, game.tower.rows - 1,
		"DAYBREAK no shade left" if remaining == 0 else "daybreak in %d" % remaining,
		int(roundf(game.sun.progress(game.turn) * 100.0)),
		int(roundf(game.sun.shadow_angle_deg(game.turn))),
	]
	_status.add_theme_color_override("font_color",
		Color(1.0, 0.45, 0.3) if remaining <= 25 else Color(0.92, 0.90, 0.82))
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
		parts.append("ambush +%d%s" % [banked, "  READY" if loadout.ambush_ready else ""])
	for id in [Upgrade.Id.JUMP, Upgrade.Id.CARVE, Upgrade.Id.RAPPEL, Upgrade.Id.SUREFOOT]:
		if loadout.has(id):
			parts.append(Upgrade.of(id).display.to_lower())
	return "    ".join(parts)
