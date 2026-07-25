class_name Game extends Node


signal turn_advanced(turn: int)
signal actor_moved(actor: Actor, from: Vector2i, to: Vector2i)
signal hp_changed(actor: Actor, hp: int)
signal run_started()
signal run_ended(won: bool)
signal actor_died(actor: Actor)
signal actor_spawned(actor: Actor)
signal enemy_telegraphed(actor: Actor)
signal actor_attacked(attacker: Actor, target: Actor)
signal tower_changed(pos: Vector2i)
signal upgrade_picked(pickup: Pickup, gained: bool)
signal upgrade_lapsed(upgrade_id: int)
signal letter_sent(letter: Letter, index: int, turns_gained: int)

var tower: TowerData
var sun: SunModel
var light: LightField
var actors: Array[Actor] = []
var turn: int = 0
var running: bool = false
var won: bool = false

var burn_per_turn: int = Tuning.BURN_PER_TURN
var regen_per_turn: int = Tuning.REGEN_PER_TURN
var heal_in_shade: bool = Tuning.HEAL_IN_SHADE
var player_damage: int = Tuning.PLAYER_DAMAGE
var enemies_enabled: bool = true
var enemy_scale: float = 1.0

var enemy_turn: EnemyTurn
var pickups: Array[Pickup] = []
var letters: Array[Letter] = []
var _letters_sent: int = 0


var player: Actor:
	get:
		return actors[0] if not actors.is_empty() else null


func start(p_seed: int = Tuning.DEFAULT_SEED) -> void:
	var builder := TowerBuilder.new(p_seed)
	builder.enemy_scale = enemy_scale
	tower = builder.build()
	sun = SunModel.new()
	light = LightField.new()
	enemy_turn = EnemyTurn.new(self)
	turn = 0
	running = true
	won = false

	var hero := Actor.new()
	hero.kind = Actor.Kind.PLAYER
	hero.pos = _spawn_position()
	hero.loadout = Loadout.new()
	actors = [hero]
	pickups = builder.pickups
	letters = builder.letters
	_letters_sent = 0
	if enemies_enabled:
		_spawn_enemies(builder.spawns, hero.pos)

	rebind_light()
	run_started.emit()
	hp_changed.emit(hero, hero.hp)


func _spawn_enemies(spawns: Array, player_pos: Vector2i) -> void:
	for spawn: Dictionary in spawns:
		var pos: Vector2i = spawn["pos"]
		if absi(tower.col_delta(pos.x, player_pos.x)) <= 1 and absi(pos.y - player_pos.y) <= 1:
			continue
		if actor_at(pos) != null:
			continue
		var enemy := Actor.create_enemy(spawn["species"], pos)
		enemy.leash = spawn.get("leash", 0)
		enemy.anchor = spawn.get("anchor", pos)
		actors.append(enemy)


func _spawn_position() -> Vector2i:
	for col in tower.cols:
		var candidate := Vector2i(col, 0)
		var cell: Cell = tower.at(candidate)
		if cell != null and cell.route and tower.player_can_stand(candidate):
			return candidate
	for col in tower.cols_per_face:
		var candidate := Vector2i(col, 0)
		if tower.player_can_stand(candidate):
			return candidate
	for row in tower.rows:
		for col in tower.cols:
			var candidate := Vector2i(col, row)
			if tower.player_can_stand(candidate):
				return candidate
	return Vector2i.ZERO


func try_move(dir: Vector2i) -> bool:
	if not running or player == null:
		return false
	var target := tower.wrap_pos(player.pos + dir)
	if not tower.in_bounds(target):
		return false

	var occupant := actor_at(target)
	if occupant != null:
		if occupant.is_player():
			return false
		_player_attack(occupant)
		advance_turn()
		return true

	if not tower.can_player_enter(player.pos, target):
		return _try_contextual(dir, target)

	return _move_player_to(target)


func _try_contextual(dir: Vector2i, target: Vector2i) -> bool:
	if player.loadout == null:
		return false

	if dir == Vector2i(0, 1) and player.loadout.has(Upgrade.Id.JUMP) \
			and not tower.is_blocked(target):
		if _move_player_to(drop_landing()):
			return true

	if dir.y == 0 and player.loadout.has(Upgrade.Id.RAPPEL) \
			and tower.barred_edge(player.pos, target):
		if _move_player_to(drop_landing()):
			return true

	if dir == Vector2i(0, -1) and player.loadout.has(Upgrade.Id.SUREFOOT) \
			and tower.player_can_stand(target) and tower.barred_edge(player.pos, target):
		return _move_player_to(target)

	var cell: Cell = tower.at(target)
	if player.loadout.has(Upgrade.Id.CARVE) and cell != null \
			and cell.kind != Cell.Kind.WINDOW and _rendable(dir, target):
		_break_cell(dir, target)
		return true

	return false


func _move_player_to(dest: Vector2i) -> bool:
	if dest == player.pos:
		return false
	if player.loadout != null:
		player.loadout.break_stillness()
	var from := player.pos
	player.pos = dest
	actor_moved.emit(player, from, dest)
	advance_turn()
	_check_pickup()
	_check_letter()
	return true


func drop_landing() -> Vector2i:
	var landing := player.pos
	for step in range(1, tower.rows):
		var candidate := Vector2i(player.pos.x, player.pos.y + step)
		if not tower.player_can_stand(candidate) or actor_at(candidate) != null:
			break
		landing = candidate
	return landing


func _rendable(dir: Vector2i, target: Vector2i) -> bool:
	var cell: Cell = tower.at(target)
	if cell == null:
		return false
	if cell.blocked:
		return true
	var flag := Cell.bar_for(dir)
	return flag != 0 and cell.bars_side(Cell.opposite(flag))


func _break_cell(dir: Vector2i, pos: Vector2i) -> void:
	var cell: Cell = tower.at(pos)
	if cell == null:
		return
	if cell.blocked:
		cell.blocked = false
		cell.kind = Cell.Kind.WALL
	else:
		var flag := Cell.bar_for(dir)
		cell.bars &= ~Cell.opposite(flag)
		var near: Cell = tower.at(player.pos)
		if near != null:
			near.bars &= ~flag
		if cell.bars == 0:
			cell.kind = Cell.Kind.WALL
	tower_changed.emit(pos)
	if player != null and player.loadout != null:
		player.loadout.break_stillness()
	advance_turn()


func _check_pickup() -> void:
	if not running or player == null or player.loadout == null:
		return
	var pickup := pickup_at(player.pos)
	if pickup == null:
		return
	var upgrade := Upgrade.of(pickup.upgrade_id)
	if not player.loadout.gains_from(upgrade):
		pickup.taken = true
		upgrade_picked.emit(pickup, false)
		return
	if not can_afford(pickup):
		return
	player.hp -= pickup.price()
	player.loadout.buy(upgrade)
	pickup.taken = true
	hp_changed.emit(player, player.hp)
	upgrade_picked.emit(pickup, true)


func _check_letter() -> void:
	if not running or player == null:
		return
	var letter := letter_at(player.pos)
	if letter == null:
		return
	letter.sent = true
	var index := _letters_sent
	_letters_sent += 1
	sun.dawn_turns += letter.turns()
	rebind_light()
	letter_sent.emit(letter, index, letter.turns())
	turn_advanced.emit(turn)


func _player_attack(target: Actor) -> void:
	actor_attacked.emit(player, target)
	damage(target, attack_power())
	if player.loadout != null:
		player.loadout.break_stillness()
	if target.is_alive():
		return
	var gained := target.blood()
	if gained <= 0:
		return
	player.hp = mini(player.max_hp, player.hp + gained)
	hp_changed.emit(player, player.hp)


func damage(target: Actor, amount: int) -> void:
	target.hp = maxi(0, target.hp - amount)
	hp_changed.emit(target, target.hp)
	if not target.is_alive() and not target.is_player():
		kill(target)


func kill(target: Actor) -> void:
	if target.is_player():
		return
	target.hp = 0
	actors.erase(target)
	actor_died.emit(target)


func rebind_light() -> void:
	light.bind(tower, sun, turn, lantern_positions())


func lantern_positions() -> Array:
	var positions: Array = []
	for actor in actors:
		if not actor.is_player() and actor.species.id == Species.Id.LANTERN_GUARD:
			positions.append(actor.pos)
	if positions.size() <= Tuning.MAX_VISIBLE_LANTERNS:
		return positions

	var origin: Vector2i = player.pos if player != null else Vector2i.ZERO
	positions.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return _lantern_distance_sq(a, origin) < _lantern_distance_sq(b, origin))
	positions.resize(Tuning.MAX_VISIBLE_LANTERNS)
	return positions


func _lantern_distance_sq(pos: Vector2i, origin: Vector2i) -> int:
	var dx := tower.col_delta(origin.x, pos.x)
	var dy := pos.y - origin.y
	return dx * dx + dy * dy


func attack_power() -> int:
	if player == null or player.loadout == null:
		return player_damage
	return player_damage + player.loadout.strength() + player.loadout.ambush_bonus()


func pickup_at(pos: Vector2i) -> Pickup:
	var wrapped := tower.wrap_pos(pos)
	for pickup in pickups:
		if pickup.pos == wrapped and not pickup.taken:
			return pickup
	return null


func can_afford(pickup: Pickup) -> bool:
	return player != null and player.hp - pickup.price() >= 1


func letter_at(pos: Vector2i) -> Letter:
	var wrapped := tower.wrap_pos(pos)
	for letter in letters:
		if letter.pos == wrapped and not letter.sent:
			return letter
	return null


func letters_sent() -> int:
	return _letters_sent


func actor_at(pos: Vector2i) -> Actor:
	var wrapped := tower.wrap_pos(pos)
	for actor in actors:
		if actor.pos == wrapped:
			return actor
	return null


func wait_turn() -> bool:
	if not running:
		return false
	advance_turn()
	if player != null and player.loadout != null:
		player.loadout.arm_ambush()
	return true


func advance_turn() -> void:
	turn += 1
	rebind_light()

	_expire_powers()

	if enemies_enabled and enemy_turn != null:
		enemy_turn.run()
		rebind_light()

	if player != null:
		_apply_light(player)

	turn_advanced.emit(turn)
	_check_end_conditions()


func _expire_powers() -> void:
	if player == null or player.loadout == null:
		return
	for id: int in player.loadout.tick(turn):
		upgrade_lapsed.emit(id)


func _apply_light(actor: Actor) -> void:
	var before := actor.hp
	match light.state_at(actor.pos):
		LightField.State.LIT:
			if actor.loadout == null or not actor.loadout.spend_grace():
				actor.hp = maxi(0, actor.hp - burn_per_turn)
		LightField.State.DARK:
			actor.hp = mini(actor.max_hp, actor.hp + regen_per_turn)
			if actor.loadout != null:
				actor.loadout.refill_grace()
		LightField.State.SHADED:
			if heal_in_shade:
				actor.hp = mini(actor.max_hp, actor.hp + regen_per_turn)
			if actor.loadout != null:
				actor.loadout.refill_grace()
	if actor.hp != before:
		hp_changed.emit(actor, actor.hp)


func _check_end_conditions() -> void:
	if player == null:
		return
	if player.pos.y >= tower.rows - 1:
		_end_run(true)
	elif not player.is_alive():
		_end_run(false)


func _end_run(p_won: bool) -> void:
	running = false
	won = p_won
	run_ended.emit(p_won)


func debug_set_turn(p_turn: int) -> void:
	turn = maxi(0, p_turn)
	rebind_light()
	turn_advanced.emit(turn)
