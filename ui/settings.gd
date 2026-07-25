class_name Settings


const PATH := "user://settings.cfg"
const SECTION := "settings"

const BUSES := ["Master", "Music", "SFX"]

static var volumes := {"Master": 1.0, "Music": 1.0, "SFX": 1.0}
static var fullscreen := false
static var narration_played := false


static func load_from(path: String = PATH) -> void:
	var config := ConfigFile.new()
	if config.load(path) != OK:
		return
	for bus in BUSES:
		volumes[bus] = clampf(float(config.get_value(SECTION, _volume_key(bus), 1.0)), 0.0, 1.0)
	fullscreen = bool(config.get_value(SECTION, "fullscreen", false))
	narration_played = bool(config.get_value(SECTION, "narration_played", false))


static func save_to(path: String = PATH) -> void:
	var config := ConfigFile.new()
	for bus in BUSES:
		config.set_value(SECTION, _volume_key(bus), volumes[bus])
	config.set_value(SECTION, "fullscreen", fullscreen)
	config.set_value(SECTION, "narration_played", narration_played)
	config.save(path)


static func apply() -> void:
	for bus in BUSES:
		apply_volume(bus)
	if fullscreen and not OS.has_feature("web"):
		apply_fullscreen()


static func set_volume(bus: String, linear: float) -> void:
	volumes[bus] = clampf(linear, 0.0, 1.0)
	apply_volume(bus)


static func apply_volume(bus: String) -> void:
	var index := AudioServer.get_bus_index(bus)
	if index < 0:
		return
	var linear: float = volumes[bus]
	AudioServer.set_bus_mute(index, is_zero_approx(linear))
	if not is_zero_approx(linear):
		AudioServer.set_bus_volume_db(index, linear_to_db(linear))


static func set_fullscreen(enabled: bool) -> void:
	fullscreen = enabled
	apply_fullscreen()


static func apply_fullscreen() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen
		else DisplayServer.WINDOW_MODE_WINDOWED)


static func is_window_fullscreen() -> bool:
	var mode := DisplayServer.window_get_mode()
	return mode == DisplayServer.WINDOW_MODE_FULLSCREEN \
		or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN


static func _volume_key(bus: String) -> String:
	return "volume_%s" % bus.to_lower()
