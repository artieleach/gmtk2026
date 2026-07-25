class_name Menu extends CanvasLayer


signal play_pressed()
signal resume_pressed()
signal restart_pressed()
signal quit_to_title_pressed()

enum Screen { TITLE, PAUSE, OPTIONS, CREDITS }

const BACKDROP_OPAQUE := Color(TowerView.SKY, 1.0)
const BACKDROP_DIM := Color(TowerView.SKY, 0.55)

@onready var _backdrop: ColorRect = %Backdrop
@onready var _fullscreen_check: CheckButton = %Fullscreen
@onready var _roots: Dictionary = {
	Screen.TITLE: %TitleScreen,
	Screen.PAUSE: %PauseScreen,
	Screen.OPTIONS: %OptionsScreen,
	Screen.CREDITS: %CreditsScreen,
}

var _stack: Array[int] = []

var _volume_sliders: Dictionary = {}
var _syncing: bool = false


func _ready() -> void:
	%GameTitle.text = String(ProjectSettings.get_setting("application/config/name", ""))
	%Quit.visible = not OS.has_feature("web")
	for bus: String in Settings.BUSES:
		_volume_sliders[bus] = %Volumes.get_node("%s/Slider" % bus)


func open(screen: int) -> void:
	if screen == Screen.OPTIONS:
		_sync_options()
	_stack.append(screen)
	_refresh()


func back() -> void:
	if _stack.is_empty():
		return
	if _stack.size() == 1:
		if _stack[0] == Screen.PAUSE:
			resume_pressed.emit()
		return
	_stack.pop_back()
	_refresh()


func close() -> void:
	_stack.clear()
	_refresh()


func is_open() -> bool:
	return not _stack.is_empty()


func _refresh() -> void:
	var current: int = _stack[-1] if not _stack.is_empty() else -1
	for screen: int in _roots:
		_roots[screen].visible = screen == current
	_backdrop.visible = current != -1
	if current == -1:
		return
	_backdrop.color = BACKDROP_OPAQUE if _stack[0] == Screen.TITLE else BACKDROP_DIM
	_focus_first(_roots[current])


func _focus_first(root: Node) -> bool:
	for child in root.get_children():
		if child is Control:
			var control := child as Control
			if not control.is_visible_in_tree():
				continue
			if control.focus_mode == Control.FOCUS_ALL:
				control.grab_focus()
				return true
		if _focus_first(child):
			return true
	return false


func _unhandled_input(event: InputEvent) -> void:
	if _stack.is_empty():
		return
	if event.is_action_pressed("cancel"):
		back()
		get_viewport().set_input_as_handled()


func _on_play_pressed() -> void:
	play_pressed.emit()


func _on_resume_pressed() -> void:
	resume_pressed.emit()


func _on_restart_pressed() -> void:
	restart_pressed.emit()


func _on_quit_to_title_pressed() -> void:
	quit_to_title_pressed.emit()


func _on_options_pressed() -> void:
	open(Screen.OPTIONS)


func _on_credits_pressed() -> void:
	open(Screen.CREDITS)


func _on_quit_pressed() -> void:
	get_tree().quit()


func _sync_options() -> void:
	_syncing = true
	for bus: String in _volume_sliders:
		_volume_sliders[bus].value = Settings.volumes[bus]
	_fullscreen_check.button_pressed = Settings.is_window_fullscreen()
	_syncing = false


func _on_volume_changed(value: float, bus: String) -> void:
	if _syncing:
		return
	Settings.set_volume(bus, value)
	Settings.save_to()


func _on_fullscreen_toggled(pressed: bool) -> void:
	if _syncing:
		return
	Settings.set_fullscreen(pressed)
	Settings.save_to()
