extends Node2D


const CARDINALS := {
	"up": Vector2i(0, -1), "down": Vector2i(0, 1),
	"left": Vector2i(-1, 0), "right": Vector2i(1, 0),
}
const DIAGONALS := {
	"up-left": Vector2i(-1, -1), "up-right": Vector2i(1, -1),
	"down-left": Vector2i(-1, 1), "down-right": Vector2i(1, 1),
}

const OFFER_ACTIONS: Array[StringName] = ["offer_1", "offer_2", "offer_3"]

var game: Game
var tower_view: TowerView
var backdrop_view: BackdropView
var actor_view: ActorView
var barrier_view: BarrierView
var hud: Hud
var menu: Menu
var music: MusicPlayer
var sfx: SfxPlayer

var _run: Node2D

var _seed: int = Tuning.DEFAULT_SEED

var _held: Dictionary = {}


func _ready() -> void:
	Settings.load_from()
	Settings.apply()

	menu = Menu.new()
	menu.name = "Menu"
	menu.play_pressed.connect(_on_play_pressed)
	menu.resume_pressed.connect(_on_resume_pressed)
	menu.restart_pressed.connect(_on_restart_pressed)
	menu.quit_to_title_pressed.connect(_on_quit_to_title_pressed)
	add_child(menu)

	music = MusicPlayer.new()
	music.name = "Music"
	add_child(music)
	music.play(MusicPlayer.MENU)

	menu.open(Menu.Screen.TITLE)


func _start_run() -> void:
	_end_run()
	_reset_move_state()

	_run = Node2D.new()
	_run.name = "Run"
	add_child(_run)

	game = Game.new()
	game.name = "Game"
	_run.add_child(game)

	tower_view = TowerView.new()
	tower_view.name = "TowerView"
	tower_view.game = game
	_run.add_child(tower_view)

	backdrop_view = BackdropView.new()
	backdrop_view.name = "BackdropView"
	backdrop_view.tower_view = tower_view
	backdrop_view.z_index = -1
	tower_view.add_child(backdrop_view)

	actor_view = ActorView.new()
	actor_view.name = "ActorView"
	actor_view.game = game
	actor_view.tower_view = tower_view
	actor_view.z_index = 1
	tower_view.add_child(actor_view)

	barrier_view = BarrierView.new()
	barrier_view.name = "BarrierView"
	barrier_view.game = game
	barrier_view.tower_view = tower_view
	barrier_view.z_index = 2
	tower_view.add_child(barrier_view)

	hud = Hud.new()
	hud.name = "Hud"
	hud.game = game
	_run.add_child(hud)

	sfx = SfxPlayer.new()
	sfx.name = "Sfx"
	sfx.game = game
	_run.add_child(sfx)

	game.start(_seed)


func _end_run() -> void:
	if _run != null:
		remove_child(_run)
		_run.queue_free()
		_run = null
	game = null
	tower_view = null
	backdrop_view = null
	actor_view = null
	barrier_view = null
	hud = null
	sfx = null


func _set_paused(paused: bool) -> void:
	get_tree().paused = paused


func _on_play_pressed() -> void:
	menu.close()
	_set_paused(false)
	music.play(MusicPlayer.GAME)
	_start_run()


func _on_resume_pressed() -> void:
	menu.close()
	_set_paused(false)


func _on_restart_pressed() -> void:
	menu.close()
	_set_paused(false)
	music.play(MusicPlayer.GAME)
	game.start(_seed)


func _on_quit_to_title_pressed() -> void:
	_end_run()
	_set_paused(false)
	music.play(MusicPlayer.MENU)
	menu.close()
	menu.open(Menu.Screen.TITLE)


func _unhandled_input(event: InputEvent) -> void:
	if game == null:
		return
	if event.is_action_pressed("restart"):
		game.start(_seed)
		return
	if event.is_action_pressed("new_run"):
		_seed = randi()
		game.start(_seed)
		return
	if OS.is_debug_build():
		if event.is_action_pressed("debug_sun_forward"):
			game.debug_set_turn(game.turn + 1)
			return
		if event.is_action_pressed("debug_sun_back"):
			game.debug_set_turn(game.turn - 1)
			return

	if game.pending_altar != null:
		_reset_move_state()
		_handle_altar(event)
		return

	if event.is_action_pressed("cancel"):
		_reset_move_state()
		_set_paused(true)
		menu.open(Menu.Screen.PAUSE)
		return

	if not game.running or tower_view.is_rotating():
		_reset_move_state()
		return

	for action in CARDINALS:
		if event.is_action_pressed(action):
			_cardinal_pressed(CARDINALS[action])
			return
		if event.is_action_released(action):
			_cardinal_released(CARDINALS[action])
			return
	for action in DIAGONALS:
		if event.is_action_pressed(action):
			game.try_move(DIAGONALS[action])
			return
	if event.is_action_pressed("wait"):
		game.wait_turn()


func _cardinal_pressed(dir: Vector2i) -> void:
	if _held.has(dir):
		return
	var partner := _perpendicular_held(dir)
	_held[dir] = false
	if partner != Vector2i.ZERO:
		_held[partner] = true
		_held[dir] = true
		game.try_move(partner + dir)


func _cardinal_released(dir: Vector2i) -> void:
	if not _held.has(dir):
		return
	var consumed: bool = _held[dir]
	_held.erase(dir)
	if not consumed:
		game.try_move(dir)


func _perpendicular_held(dir: Vector2i) -> Vector2i:
	for held in _held:
		if held.x * dir.x + held.y * dir.y == 0:
			return held
	return Vector2i.ZERO


func _reset_move_state() -> void:
	_held.clear()


func _handle_altar(event: InputEvent) -> void:
	var altar := game.pending_altar
	for i in OFFER_ACTIONS.size():
		if event.is_action_pressed(OFFER_ACTIONS[i]):
			if i < altar.offers.size():
				game.buy(altar, altar.offers[i])
			return
	if event.is_action_pressed("cancel"):
		game.close_altar()
