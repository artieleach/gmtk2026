class_name EnemyTurn extends RefCounted


var game: Game


func _init(p_game: Game) -> void:
	game = p_game


func run() -> void:
	if game.player == null:
		return
	for enemy in game.actors.duplicate():
		_take_turn(enemy)


func _take_turn(enemy: Actor) -> void:
	if enemy.is_player() or not enemy.is_alive():
		return
	if not is_active(enemy):
		return

	if _light_kills(enemy):
		game.kill(enemy)
		return
	if _is_frozen(enemy):
		enemy.windup_turns = 0
		enemy.next_action_turn = game.turn + 1
		return
	if game.turn < enemy.next_action_turn:
		return

	dispatch(enemy)
	if enemy.is_winding_up():
		enemy.next_action_turn = game.turn + 1
	else:
		enemy.next_action_turn = game.turn + maxi(1, enemy.species.move_period)


func is_active(enemy: Actor) -> bool:
	var player := game.player
	if player == null:
		return false
	return absi(enemy.pos.y - player.pos.y) <= Tuning.ENEMY_ACTIVE_ROWS


func dispatch(enemy: Actor) -> void:
	match enemy.species.brain_id:
		&"sentry":
			Brains.sentry(enemy, self)
		&"chaser":
			Brains.chaser(enemy, self)
		&"stalker":
			Brains.stalker(enemy, self)
		&"lunger":
			Brains.lunger(enemy, self)
		&"patroller":
			Brains.patroller(enemy, self)
		&"mason":
			Brains.mason(enemy, self)
		&"hive":
			Brains.hive(enemy, self)
		_:
			push_warning("EnemyTurn: unknown brain '%s'" % enemy.species.brain_id)


func _light_kills(enemy: Actor) -> bool:
	return enemy.species.light_rule == Species.LightRule.SHADE_ONLY \
		and game.light.state_at(enemy.pos) == LightField.State.LIT


func _is_frozen(enemy: Actor) -> bool:
	return enemy.species.light_rule == Species.LightRule.FREEZES_IN_LIGHT \
		and game.light.state_at(enemy.pos) == LightField.State.LIT


func player() -> Actor:
	return game.player


func is_adjacent(a: Vector2i, b: Vector2i) -> bool:
	if a == b:
		return false
	return absi(game.tower.col_delta(a.x, b.x)) <= 1 and absi(a.y - b.y) <= 1


func is_free(pos: Vector2i) -> bool:
	return game.tower.in_bounds(pos) \
		and not game.tower.is_blocked(pos) \
		and game.actor_at(pos) == null


func lunge_target_for(enemy: Actor) -> Vector2i:
	var target := game.player
	if target == null:
		return Brains.NO_TARGET
	for dir in TowerData.DIRS:
		var probe := enemy.pos
		for step in range(1, enemy.species.lunge_range + 1):
			probe = game.tower.wrap_pos(probe + dir)
			if not game.tower.in_bounds(probe):
				break
			if probe == target.pos:
				if step >= 2:
					return probe
				break
			if game.tower.is_blocked(probe) or game.actor_at(probe) != null:
				break
	return Brains.NO_TARGET


func step_toward(enemy: Actor, goal: Vector2i, avoid_light: bool) -> bool:
	var wanted := Vector2i(
		signi(game.tower.col_delta(enemy.pos.x, goal.x)),
		signi(goal.y - enemy.pos.y))
	if wanted == Vector2i.ZERO:
		return false

	var index := TowerData.DIRS.find(wanted)
	if index < 0:
		return false
	for offset in [0, 1, -1]:
		var dir: Vector2i = TowerData.DIRS[wrapi(index + offset, 0, TowerData.DIRS.size())]
		var next := game.tower.wrap_pos(enemy.pos + dir)
		if _can_enter(enemy, next, avoid_light):
			move_to(enemy, next)
			return true
	return false


func step_dir(enemy: Actor, dir: Vector2i, avoid_light: bool) -> bool:
	var next := game.tower.wrap_pos(enemy.pos + dir)
	if not _can_enter(enemy, next, avoid_light):
		return false
	move_to(enemy, next)
	return true


func brood_count(hive: Actor) -> int:
	var count := 0
	for actor in game.actors:
		if actor.is_player() or actor.species.id != Species.Id.SWARMLING:
			continue
		if actor.anchor == hive.pos:
			count += 1
	return count


func spawn_brood(hive: Actor) -> void:
	for dir in TowerData.DIRS:
		var pos := game.tower.wrap_pos(hive.pos + dir)
		if not is_free(pos):
			continue
		var brood := Actor.create_enemy(Species.Id.SWARMLING, pos)
		brood.anchor = hive.pos
		brood.leash = Tuning.NEST_LEASH
		game.actors.append(brood)
		game.actor_spawned.emit(brood)
		return


func barrier_at(pos: Vector2i) -> bool:
	var cell: Cell = game.tower.at(pos)
	return cell != null and cell.bars != 0


func gnaw(enemy: Actor) -> void:
	var cell: Cell = game.tower.at(enemy.pos)
	if cell == null or cell.bars == 0:
		return
	var walls := cell.bars
	for flag in [Cell.BAR_TOP, Cell.BAR_RIGHT, Cell.BAR_BOTTOM, Cell.BAR_LEFT]:
		if walls & flag == 0:
			continue
		var beyond := game.tower.wrap_pos(enemy.pos + Cell.dir_for(flag))
		for changed in game.tower.unwall_edge(enemy.pos, beyond):
			game.notify_tower_changed(changed)
	game.barrier_broken.emit(enemy.pos, false)


func nearest_barrier(from: Vector2i) -> Vector2i:
	const SEARCH := 6
	var best := Brains.NO_TARGET
	var best_distance := 9999
	for row in range(from.y - SEARCH, from.y + SEARCH + 1):
		for offset in range(-SEARCH, SEARCH + 1):
			var pos := game.tower.wrap_pos(Vector2i(from.x + offset, row))
			if not game.tower.in_bounds(pos) or not barrier_at(pos):
				continue
			var distance := maxi(absi(offset), absi(row - from.y))
			if distance < best_distance:
				best_distance = distance
				best = pos
	return best


func _can_enter(enemy: Actor, pos: Vector2i, avoid_light: bool) -> bool:
	if not is_free(pos):
		return false
	if avoid_light and game.light.state_at(pos) == LightField.State.LIT:
		return false
	if enemy.leash > 0:
		var away := maxi(
			absi(game.tower.col_delta(enemy.anchor.x, pos.x)),
			absi(pos.y - enemy.anchor.y))
		if away > enemy.leash:
			return false
	return true


func move_to(enemy: Actor, pos: Vector2i) -> void:
	var from := enemy.pos
	enemy.pos = pos
	game.actor_moved.emit(enemy, from, pos)


func attack(enemy: Actor, target: Actor) -> void:
	game.actor_attacked.emit(enemy, target)
	game.damage(target, enemy.species.damage)


func begin_windup(enemy: Actor, target: Vector2i) -> void:
	enemy.windup_turns = 1
	enemy.lunge_target = target
	game.enemy_telegraphed.emit(enemy)


func resolve_lunge(enemy: Actor) -> void:
	enemy.windup_turns = 0
	var target := enemy.lunge_target
	var victim := game.actor_at(target)
	if victim != null and victim.is_player():
		attack(enemy, victim)
	elif is_free(target):
		move_to(enemy, target)
