extends Node2D


const MOVE_KEYS := {
	KEY_W: Vector2i(0, -1), KEY_UP: Vector2i(0, -1), KEY_KP_8: Vector2i(0, -1),
	KEY_S: Vector2i(0, 1), KEY_DOWN: Vector2i(0, 1), KEY_KP_2: Vector2i(0, 1),
	KEY_A: Vector2i(-1, 0), KEY_LEFT: Vector2i(-1, 0), KEY_KP_4: Vector2i(-1, 0),
	KEY_D: Vector2i(1, 0), KEY_RIGHT: Vector2i(1, 0), KEY_KP_6: Vector2i(1, 0),
	KEY_Q: Vector2i(-1, -1), KEY_KP_7: Vector2i(-1, -1),
	KEY_E: Vector2i(1, -1), KEY_KP_9: Vector2i(1, -1),
	KEY_Z: Vector2i(-1, 1), KEY_KP_1: Vector2i(-1, 1),
	KEY_C: Vector2i(1, 1), KEY_KP_3: Vector2i(1, 1),
}
const WAIT_KEYS: Array[int] = [KEY_X, KEY_KP_5, KEY_SPACE]

const ABILITY_KEYS := {
	KEY_1: Upgrade.Id.JUMP,
	KEY_2: Upgrade.Id.SHADE,
	KEY_3: Upgrade.Id.TERROR,
	KEY_4: Upgrade.Id.CARVE,
}
const OFFER_KEYS: Array[int] = [KEY_1, KEY_2, KEY_3]

var _armed: int = -1

var game: Game
var tower_view: TowerView
var actor_view: ActorView
var hud: Hud

var _seed: int = Tuning.DEFAULT_SEED


func _ready() -> void:
	game = Game.new()
	game.name = "Game"
	add_child(game)

	tower_view = TowerView.new()
	tower_view.name = "TowerView"
	tower_view.game = game
	add_child(tower_view)

	actor_view = ActorView.new()
	actor_view.name = "ActorView"
	actor_view.game = game
	actor_view.tower_view = tower_view
	actor_view.z_index = 1
	tower_view.add_child(actor_view)

	hud = Hud.new()
	hud.name = "Hud"
	hud.game = game
	add_child(hud)

	game.start(_seed)


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	var key: int = event.physical_keycode if event.physical_keycode != 0 else event.keycode

	match key:
		KEY_R:
			game.start(_seed)
			return
		KEY_N:
			_seed = randi()
			game.start(_seed)
			return
		KEY_BRACKETRIGHT:
			if OS.is_debug_build():
				game.debug_set_turn(game.turn + 1)
			return
		KEY_BRACKETLEFT:
			if OS.is_debug_build():
				game.debug_set_turn(game.turn - 1)
			return

	if game.pending_altar != null:
		_handle_altar(key)
		return

	if not game.running or tower_view.is_rotating():
		return

	if ABILITY_KEYS.has(key):
		_press_ability(ABILITY_KEYS[key])
	elif MOVE_KEYS.has(key):
		_press_direction(MOVE_KEYS[key])
	elif key in WAIT_KEYS:
		_armed = -1
		game.wait_turn()
	elif key == KEY_ESCAPE:
		_armed = -1


func _handle_altar(key: int) -> void:
	var altar := game.pending_altar
	var choice := OFFER_KEYS.find(key)
	if choice >= 0 and choice < altar.offers.size():
		game.buy(altar, altar.offers[choice])
	elif key == KEY_ESCAPE:
		game.close_altar()


func _press_ability(upgrade_id: int) -> void:
	if not game.player.loadout.can_use(upgrade_id):
		return
	if Upgrade.of(upgrade_id).needs_direction:
		_armed = -1 if _armed == upgrade_id else upgrade_id
		return
	_armed = -1
	match upgrade_id:
		Upgrade.Id.SHADE:
			game.use_shade()
		Upgrade.Id.TERROR:
			game.use_terror()


func _press_direction(dir: Vector2i) -> void:
	if _armed < 0:
		game.try_move(dir)
		return
	var armed := _armed
	_armed = -1
	match armed:
		Upgrade.Id.JUMP:
			game.use_jump(dir)
		Upgrade.Id.CARVE:
			game.use_carve(dir)
