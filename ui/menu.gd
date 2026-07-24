class_name Menu extends CanvasLayer


signal play_pressed()
signal resume_pressed()
signal restart_pressed()
signal quit_to_title_pressed()

enum Screen { TITLE, PAUSE, OPTIONS, CREDITS }

const LAYER := 10

const TITLE_SIZE := 72
const HEADING_SIZE := 44
const BUTTON_SIZE := 30
const TEXT := Color(0.92, 0.90, 0.82)
const ACCENT := Color(1.0, 0.82, 0.72)

const BACKDROP_OPAQUE := Color(TowerView.SKY, 1.0)
const BACKDROP_DIM := Color(TowerView.SKY, 0.55)

var _backdrop: ColorRect
var _roots: Dictionary = {}
var _stack: Array[int] = []

var _volume_sliders: Dictionary = {}
var _fullscreen_check: CheckButton
var _syncing: bool = false


func _ready() -> void:
	layer = LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS

	_backdrop = ColorRect.new()
	_backdrop.color = BACKDROP_OPAQUE
	_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_backdrop.visible = false
	add_child(_backdrop)

	_build_title()
	_build_pause()
	_build_options()
	_build_credits()


func _build_title() -> void:
	var box := _make_screen(Screen.TITLE,
		String(ProjectSettings.get_setting("application/config/name", "")), TITLE_SIZE)
	_make_button(box, "Play", func() -> void: play_pressed.emit())
	_make_button(box, "Options", func() -> void: open(Screen.OPTIONS))
	_make_button(box, "Credits", func() -> void: open(Screen.CREDITS))
	if not OS.has_feature("web"):
		_make_button(box, "Quit", func() -> void: get_tree().quit())


func _build_pause() -> void:
	var box := _make_screen(Screen.PAUSE, "Paused", HEADING_SIZE)
	_make_button(box, "Resume", func() -> void: resume_pressed.emit())
	_make_button(box, "Restart run", func() -> void: restart_pressed.emit())
	_make_button(box, "Options", func() -> void: open(Screen.OPTIONS))
	_make_button(box, "Credits", func() -> void: open(Screen.CREDITS))
	_make_button(box, "Quit to title", func() -> void: quit_to_title_pressed.emit())


func _build_options() -> void:
	var box := _make_screen(Screen.OPTIONS, "Options", HEADING_SIZE)
	for bus: String in Settings.BUSES:
		_volume_sliders[bus] = _make_slider(box, bus, bus)

	_fullscreen_check = CheckButton.new()
	_fullscreen_check.text = "Fullscreen"
	_fullscreen_check.add_theme_font_size_override("font_size", BUTTON_SIZE)
	_fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	box.add_child(_fullscreen_check)

	_make_button(box, "Back", back)


func _build_credits() -> void:
	var box := _make_screen(Screen.CREDITS, "Credits", HEADING_SIZE)
	_make_button(box, "Back", back)


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
		if child is Control and (child as Control).focus_mode == Control.FOCUS_ALL:
			(child as Control).grab_focus()
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


func _make_screen(screen: int, heading: String, size: int) -> VBoxContainer:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.visible = false
	add_child(root)

	var centre := CenterContainer.new()
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	centre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(centre)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	centre.add_child(box)

	var label := Label.new()
	label.text = heading
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", ACCENT)
	box.add_child(label)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 24)
	box.add_child(spacer)

	_roots[screen] = root
	return box


func _make_button(box: VBoxContainer, text: String, on_press: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.add_theme_font_size_override("font_size", BUTTON_SIZE)
	button.add_theme_color_override("font_color", TEXT)
	button.custom_minimum_size = Vector2(360, 0)
	button.pressed.connect(on_press)
	box.add_child(button)
	return button


func _make_slider(box: VBoxContainer, text: String, bus: String) -> HSlider:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	box.add_child(row)

	var label := Label.new()
	label.text = text
	label.custom_minimum_size = Vector2(140, 0)
	label.add_theme_font_size_override("font_size", BUTTON_SIZE)
	label.add_theme_color_override("font_color", TEXT)
	row.add_child(label)

	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.custom_minimum_size = Vector2(220, 0)
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slider.value_changed.connect(_on_volume_changed.bind(bus))
	row.add_child(slider)
	return slider
