class_name Game extends Node


signal turn_advanced(turn: int)
signal actor_moved(actor: Actor, from: Vector2i, to: Vector2i)
signal hp_changed(actor: Actor, hp: int)
signal run_started()
signal run_ended(won: bool)
signal actor_died(actor: Actor)
signal actor_spawned(actor: Actor)
signal enemy_telegraphed(actor: Actor)
signal tower_changed(pos: Vector2i)
signal altar_opened(altar: Altar)
signal altar_closed()

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
var altars: Array[Altar] = []
var pending_altar: Altar = null


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
	altars = builder.altars
	pending_altar = null
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
	for col in tower.cols_per_face:
		var candidate := Vector2i(col, 0)
		if not tower.is_blocked(candidate):
			return candidate
	for row in tower.rows:
		for col in tower.cols:
			var candidate := Vector2i(col, row)
			if not tower.is_blocked(candidate):
				return candidate
	return Vector2i.ZERO


func try_move(dir: Vector2i) -> bool:
	if not running or pending_altar != null or player == null:
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
		return false

	var from := player.pos
	player.pos = target
	actor_moved.emit(player, from, target)
	advance_turn()
	_check_altar()
	return true


func _check_altar() -> void:
	if not running or player == null:
		return
	var altar := altar_at(player.pos)
	if altar == null:
		return
	pending_altar = altar
	altar_opened.emit(altar)


func _player_attack(target: Actor) -> void:
	damage(target, attack_power())
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


func use_jump(dir: Vector2i) -> bool:
	if not _ready_for(Upgrade.Id.JUMP) or dir == Vector2i.ZERO:
		return false
	var landing := jump_landing(dir)
	if landing == player.pos:
		return false

	player.loadout.spend_charge(Upgrade.Id.JUMP)
	var from := player.pos
	player.pos = landing
	actor_moved.emit(player, from, landing)
	advance_turn()
	_check_altar()
	return true


func jump_landing(dir: Vector2i) -> Vector2i:
	var landing := player.pos
	for step in range(1, Tuning.JUMP_RANGE + 1):
		var candidate := tower.wrap_pos(player.pos + dir * step)
		if not tower.in_bounds(candidate):
			break
		if tower.is_blocked(candidate) or actor_at(candidate) != null:
			continue
		landing = candidate
	return landing


func use_shade() -> bool:
	if not _ready_for(Upgrade.Id.SHADE):
		return false
	var cell: Cell = tower.at(player.pos)
	if cell == null or cell.casts_shadow():
		return false
	player.loadout.spend_charge(Upgrade.Id.SHADE)
	cell.protrusion_depth = Tuning.SHADE_DEPTH
	if cell.kind != Cell.Kind.ALTAR:
		cell.kind = Cell.Kind.LEDGE
	tower.invalidate_protrusion_cache()
	tower_changed.emit(player.pos)
	advance_turn()
	return true


func use_terror() -> bool:
	if not _ready_for(Upgrade.Id.TERROR):
		return false
	player.loadout.spend_charge(Upgrade.Id.TERROR)
	for actor in actors:
		if actor.is_player():
			continue
		var reach := maxi(
			absi(tower.col_delta(player.pos.x, actor.pos.x)),
			absi(actor.pos.y - player.pos.y))
		if reach <= Tuning.TERROR_RADIUS:
			actor.feared_until_turn = turn + Tuning.TERROR_TURNS
	advance_turn()
	return true


func use_carve(dir: Vector2i) -> bool:
	if not _ready_for(Upgrade.Id.CARVE) or dir == Vector2i.ZERO:
		return false
	var target := tower.wrap_pos(player.pos + dir)
	var cell: Cell = tower.at(target)
	if cell == null or not (cell.blocked or cell.casts_shadow()):
		return false
	player.loadout.spend_charge(Upgrade.Id.CARVE)
	cell.blocked = false
	cell.protrusion_depth = 0
	cell.kind = Cell.Kind.WALL
	tower.invalidate_protrusion_cache()
	tower_changed.emit(target)
	advance_turn()
	return true


func _ready_for(upgrade_id: int) -> bool:
	return running and pending_altar == null and player != null \
		and player.loadout != null and player.loadout.can_use(upgrade_id)


func attack_power() -> int:
	var bonus := player.loadout.strength() if player != null and player.loadout != null else 0
	return player_damage + bonus


func altar_at(pos: Vector2i) -> Altar:
	var wrapped := tower.wrap_pos(pos)
	for altar in altars:
		if altar.pos == wrapped and not altar.spent:
			return altar
	return null


func can_afford(altar: Altar) -> bool:
	return player != null and player.hp - altar.price() >= 1


func buy(altar: Altar, upgrade_id: int) -> bool:
	if altar == null or altar.spent or not altar.offers.has(upgrade_id):
		return false
	if not can_afford(altar):
		return false
	player.hp -= altar.price()
	player.loadout.buy(Upgrade.of(upgrade_id))
	altar.spent = true
	pending_altar = null
	hp_changed.emit(player, player.hp)
	altar_closed.emit()
	return true


func close_altar() -> void:
	if pending_altar == null:
		return
	pending_altar = null
	altar_closed.emit()


func actor_at(pos: Vector2i) -> Actor:
	var wrapped := tower.wrap_pos(pos)
	for actor in actors:
		if actor.pos == wrapped:
			return actor
	return null


func wait_turn() -> bool:
	if not running or pending_altar != null:
		return false
	advance_turn()
	return true


func advance_turn() -> void:
	turn += 1
	rebind_light()

	if enemies_enabled and enemy_turn != null:
		enemy_turn.run()
		rebind_light()

	if player != null:
		_apply_light(player)

	turn_advanced.emit(turn)
	_check_end_conditions()


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
