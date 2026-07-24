class_name Brains extends RefCounted


const NO_TARGET := Vector2i(-1, -1)


static func sentry(enemy: Actor, api) -> void:
	var player: Actor = api.player()
	if api.is_adjacent(enemy.pos, player.pos):
		api.attack(enemy, player)


static func chaser(enemy: Actor, api) -> void:
	var player: Actor = api.player()
	if api.is_adjacent(enemy.pos, player.pos):
		api.attack(enemy, player)
		return
	if api.step_toward(enemy, player.pos, false):
		return
	if enemy.leash > 0:
		api.step_toward(enemy, enemy.anchor, false)


static func stalker(enemy: Actor, api) -> void:
	var player: Actor = api.player()
	if api.is_adjacent(enemy.pos, player.pos):
		api.attack(enemy, player)
		return
	api.step_toward(enemy, player.pos, true)


static func lunger(enemy: Actor, api) -> void:
	if enemy.is_winding_up():
		api.resolve_lunge(enemy)
		return

	var player: Actor = api.player()
	if api.is_adjacent(enemy.pos, player.pos):
		api.attack(enemy, player)
		return

	var target: Vector2i = api.lunge_target_for(enemy)
	if target != NO_TARGET:
		api.begin_windup(enemy, target)
		return

	api.step_toward(enemy, player.pos, false)


static func patroller(enemy: Actor, api) -> void:
	var player: Actor = api.player()
	if api.is_adjacent(enemy.pos, player.pos):
		api.attack(enemy, player)
		return
	if api.step_dir(enemy, enemy.patrol_dir, false):
		return
	enemy.patrol_dir = -enemy.patrol_dir
	if api.step_dir(enemy, enemy.patrol_dir, false):
		return
	enemy.patrol_dir = -enemy.patrol_dir


static func hive(enemy: Actor, api) -> void:
	if api.brood_count(enemy) >= Tuning.NEST_SWARMLINGS:
		return
	api.spawn_brood(enemy)


static func mason(enemy: Actor, api) -> void:
	var player: Actor = api.player()
	if api.is_adjacent(enemy.pos, player.pos):
		api.attack(enemy, player)
		return
	if api.barrier_at(enemy.pos):
		api.gnaw(enemy)
		return
	var target: Vector2i = api.nearest_barrier(enemy.pos)
	if target != NO_TARGET:
		api.step_toward(enemy, target, false)
