class_name TowerBuilder extends RefCounted


const MAX_BLOCKED_PER_ROW := 11
const CLEAR_MARGIN_ROWS := 2
const CARRY_EPSILON := 1e-6
const MAX_CARVES := 512

var rng := RandomNumberGenerator.new()
var segment_count: int
var rows_per_segment: int
var cols: int
var enemy_scale: float = 1.0
var spawns: Array[Dictionary] = []
var altars: Array[Altar] = []
var _creature_anchors: Array[Vector2i] = []
var _altar_anchors: Array[Vector2i] = []
var _carry: Dictionary = {}


func _init(p_seed: int = Tuning.DEFAULT_SEED, p_segments: int = Tuning.SEGMENT_COUNT,
		p_rows_per_segment: int = Tuning.ROWS_PER_SEGMENT, p_cols: int = Tuning.COLS) -> void:
	rng.seed = p_seed
	segment_count = p_segments
	rows_per_segment = p_rows_per_segment
	cols = p_cols


func build() -> TowerData:
	RoomTemplates.ensure_valid()
	var tower := TowerData.new(cols, segment_count * rows_per_segment)
	_creature_anchors.clear()
	_altar_anchors.clear()
	for index in segment_count:
		_build_segment(tower, SegmentRecipe.for_depth(index, segment_count),
			index * rows_per_segment)
	_ruin(tower)
	_clear_margins(tower)
	_enforce_row_budget(tower)
	_ensure_descendable(tower)
	_populate(tower)
	return tower


func _build_segment(tower: TowerData, recipe: SegmentRecipe, top_row: int) -> void:
	var bottom_row: int = mini(top_row + recipe.rows, tower.rows)
	for row in range(top_row, bottom_row):
		for col in cols:
			tower.at(Vector2i(col, row)).kind = recipe.base_kind

	var rooms_tall: int = tower.rows / Tuning.ROOM_H
	var room_row := top_row / Tuning.ROOM_H
	while room_row * Tuning.ROOM_H < bottom_row:
		var band := RoomTemplates.band_for(room_row, rooms_tall)
		var pool := RoomTemplates.pool_for(band)
		for face in Tuning.FACES:
			var rows: Array = pool[rng.randi_range(0, pool.size() - 1)]
			if rng.randi_range(0, 1) == 1:
				rows = RoomTemplates.mirrored(rows)
			_stamp_room(tower, rows, face * Tuning.ROOM_W, room_row * Tuning.ROOM_H)
		room_row += 1


func _stamp_room(tower: TowerData, rows: Array, left_col: int, top_row: int) -> void:
	for y in rows.size():
		var line: String = rows[y]
		var row := top_row + y
		if row >= tower.rows:
			return
		for x in line.length():
			var pos := Vector2i(tower.wrap_col(left_col + x), row)
			var spec := RoomTemplates.cell_for(line[x])
			var cell := tower.at(pos)
			if spec["kind"] != -1:
				cell.kind = spec["kind"]
			cell.bars = RoomTemplates.bars_at(rows, x, y)
			if RoomTemplates.is_window_origin(rows, x, y):
				tower.windows.append({
					"origin": pos,
					"size": RoomTemplates.window_size(line[x]),
					"open": false,
				})
			match spec["anchor"]:
				"creature":
					_creature_anchors.append(pos)
				"altar":
					_altar_anchors.append(pos)


func _ruin(tower: TowerData) -> void:
	var avg_size := (Tuning.RUBBLE_CLUSTER_MIN + Tuning.RUBBLE_CLUSTER_MAX) / 2.0
	for row in tower.rows:
		var t := float(row) / float(maxi(1, tower.rows - 1))
		var chance := lerpf(Tuning.RUIN_CHANCE_TOP, Tuning.RUIN_CHANCE_BOTTOM, t)
		var seed_chance := chance / avg_size
		for col in cols:
			var cell := tower.at(Vector2i(col, row))
			if not _can_ruin(cell):
				continue
			if rng.randf() < seed_chance:
				_grow_rubble_cluster(tower, Vector2i(col, row))


func _can_ruin(cell: Cell) -> bool:
	return cell != null and cell.bars == 0 and not cell.blocked \
		and cell.kind != Cell.Kind.WINDOW


func _grow_rubble_cluster(tower: TowerData, seed: Vector2i) -> void:
	var target := rng.randi_range(Tuning.RUBBLE_CLUSTER_MIN, Tuning.RUBBLE_CLUSTER_MAX)
	var members: Array[Vector2i] = [seed]
	_lay_rubble(tower, seed)
	var attempts := target * 8
	while members.size() < target and attempts > 0:
		attempts -= 1
		var from: Vector2i = members[rng.randi_range(0, members.size() - 1)]
		var dir: Vector2i = TowerData.DIRS[rng.randi_range(0, TowerData.DIRS.size() - 1)]
		var next := tower.wrap_pos(from + dir)
		var cell := tower.at(next)
		if not _can_ruin(cell):
			continue
		_lay_rubble(tower, next)
		members.append(next)


func _lay_rubble(tower: TowerData, pos: Vector2i) -> void:
	var cell := tower.at(pos)
	cell.kind = Cell.Kind.RUBBLE
	cell.blocked = true


func _populate(tower: TowerData) -> void:
	spawns.clear()
	altars.clear()
	_carry.clear()
	var taken: Dictionary = {}
	for index in segment_count:
		var recipe := SegmentRecipe.for_depth(index, segment_count)
		var top_row: int = index * rows_per_segment
		var bottom_row: int = mini(top_row + rows_per_segment, tower.rows)
		_populate_segment(tower, recipe, top_row, bottom_row, index, taken)
		_place_altars(tower, top_row, bottom_row, taken)


func _place_altars(tower: TowerData, top_row: int, bottom_row: int, taken: Dictionary) -> void:
	for _i in Tuning.ALTARS_PER_SEGMENT:
		var pos := _take_anchor(_altar_anchors, tower, top_row, bottom_row, taken, Terrain.BARE)
		if pos == NO_SPOT:
			pos = _find_spot(tower, top_row, bottom_row, taken, Terrain.BARE)
		if pos == NO_SPOT:
			continue
		taken[pos] = true
		tower.at(pos).kind = Cell.Kind.ALTAR
		altars.append(Altar.create(pos, _roll_offers()))


func _roll_offers() -> Array[int]:
	var pool: Array = Upgrade.all_ids().duplicate()
	var offers: Array[int] = []
	for _i in mini(Tuning.ALTAR_OFFERS, pool.size()):
		offers.append(pool.pop_at(rng.randi_range(0, pool.size() - 1)))
	return offers


func _populate_segment(tower: TowerData, recipe: SegmentRecipe, top_row: int,
		bottom_row: int, index: int, taken: Dictionary) -> void:
	for window in tower.windows:
		var origin: Vector2i = window["origin"]
		if origin.y < top_row or origin.y >= bottom_row:
			continue
		if rng.randf() >= recipe.window_swiper_chance:
			continue
		var size: Vector2i = window["size"]
		var seat := tower.wrap_pos(origin + Vector2i(size.x / 2, size.y / 2))
		if not _is_spawnable(tower, seat, taken):
			continue
		_place(tower, seat, Species.Id.WINDOW_SWIPER, 0, taken)
		window["open"] = true

	for _i in _scaled(&"gargoyle", recipe.gargoyle_count):
		var pos := _find_spot(tower, top_row, bottom_row, taken, Terrain.BARRIER)
		if pos != NO_SPOT:
			_place(tower, pos, Species.Id.GARGOYLE, 0, taken)

	for _i in _scaled(&"crawler", recipe.crawler_count):
		var pos := _find_spot(tower, top_row, bottom_row, taken)
		if pos != NO_SPOT:
			_place(tower, pos, Species.Id.CRAWLER, 0, taken)

	for _i in _scaled(&"lurker", recipe.lurker_count):
		var pos := _find_spot(tower, top_row, bottom_row, taken)
		if pos != NO_SPOT:
			_place(tower, pos, Species.Id.SHADE_LURKER, 0, taken)

	for _i in _scaled(&"guard", recipe.guard_count):
		var pos := _find_spot(tower, top_row, bottom_row, taken)
		if pos != NO_SPOT:
			_place(tower, pos, Species.Id.LANTERN_GUARD, Tuning.PATROL_LEASH, taken)

	for _i in _scaled(&"mason", recipe.mason_count):
		var pos := _find_spot(tower, top_row, bottom_row, taken, Terrain.BARRIER)
		if pos != NO_SPOT:
			_place(tower, pos, Species.Id.STONEMASON, 0, taken)

	if index > 0 and index % Tuning.NEST_EVERY_N_SEGMENTS == 0:
		_place_nest(tower, top_row, bottom_row, taken)


func _place_nest(tower: TowerData, top_row: int, bottom_row: int, taken: Dictionary) -> void:
	var anchor := _find_spot(tower, top_row, bottom_row, taken)
	if anchor == NO_SPOT:
		return
	_place(tower, anchor, Species.Id.NEST, 0, taken)
	for _i in Tuning.NEST_SWARMLINGS:
		var pos := Vector2i(
			tower.wrap_col(anchor.x + rng.randi_range(-Tuning.NEST_LEASH, Tuning.NEST_LEASH)),
			clampi(anchor.y + rng.randi_range(-Tuning.NEST_LEASH, Tuning.NEST_LEASH),
				top_row, bottom_row - 1))
		if not _is_spawnable(tower, pos, taken):
			continue
		var entry := _place(tower, pos, Species.Id.SWARMLING, Tuning.NEST_LEASH, taken)
		entry["anchor"] = anchor


func _scaled(key: StringName, density: float) -> int:
	var total: float = density * enemy_scale + _carry.get(key, 0.0)
	var whole := int(floor(total + CARRY_EPSILON))
	_carry[key] = total - float(whole)
	return whole


const NO_SPOT := Vector2i(-1, -1)


enum Terrain {
	ANY,
	BARRIER,
	BARE,
}


func _suits(tower: TowerData, pos: Vector2i, terrain: int) -> bool:
	match terrain:
		Terrain.BARRIER:
			return tower.at(pos).casts_shadow()
		Terrain.BARE:
			return not tower.at(pos).casts_shadow()
		_:
			return true


func _take_anchor(pool: Array[Vector2i], tower: TowerData, top_row: int,
		bottom_row: int, taken: Dictionary, terrain: int) -> Vector2i:
	for i in pool.size():
		var pos: Vector2i = pool[i]
		if pos.y < top_row or pos.y >= bottom_row:
			continue
		if not _is_spawnable(tower, pos, taken) or not _suits(tower, pos, terrain):
			continue
		pool.remove_at(i)
		return pos
	return NO_SPOT


func _find_spot(tower: TowerData, top_row: int, bottom_row: int, taken: Dictionary,
		terrain: int = Terrain.ANY) -> Vector2i:
	var anchored := _take_anchor(_creature_anchors, tower, top_row, bottom_row, taken, terrain)
	if anchored != NO_SPOT:
		return anchored
	for _attempt in 24:
		var pos := Vector2i(
			rng.randi_range(0, cols - 1),
			rng.randi_range(top_row, bottom_row - 1))
		if not _suits(tower, pos, terrain):
			continue
		if _is_spawnable(tower, pos, taken):
			return pos
	return NO_SPOT


func _is_spawnable(tower: TowerData, pos: Vector2i, taken: Dictionary) -> bool:
	if pos.y < Tuning.ENEMY_FREE_TOP_ROWS or pos.y >= tower.rows:
		return false
	if tower.is_blocked(pos) or taken.has(pos):
		return false
	return true


func _place(tower: TowerData, pos: Vector2i, species_id: int, leash: int,
		taken: Dictionary) -> Dictionary:
	var entry := {"pos": pos, "species": species_id, "leash": leash, "anchor": pos}
	taken[pos] = true
	spawns.append(entry)
	return entry


func _clear_margins(tower: TowerData) -> void:
	for row in CLEAR_MARGIN_ROWS:
		_clear_row(tower, row)
		_clear_row(tower, tower.rows - 1 - row)


func _clear_row(tower: TowerData, row: int) -> void:
	if row < 0 or row >= tower.rows:
		return
	for col in cols:
		var cell := tower.at(Vector2i(col, row))
		cell.blocked = false
		if cell.kind == Cell.Kind.RUBBLE:
			cell.kind = Cell.Kind.WALL


func _open_cell(tower: TowerData, pos: Vector2i) -> void:
	var cell := tower.at(pos)
	if cell == null:
		return
	cell.blocked = false
	cell.kind = Cell.Kind.WALL
	cell.bars = 0


func _enforce_row_budget(tower: TowerData) -> void:
	for row in tower.rows:
		var blocked_cols: Array[int] = []
		for col in cols:
			if tower.at(Vector2i(col, row)).blocked:
				blocked_cols.append(col)
		while blocked_cols.size() > MAX_BLOCKED_PER_ROW:
			var victim: int = blocked_cols.pop_back()
			var cell := tower.at(Vector2i(victim, row))
			cell.blocked = false
			cell.kind = Cell.Kind.WALL


func _ensure_descendable(tower: TowerData) -> void:
	for _attempt in MAX_CARVES:
		var reached := _flood_from_top(tower)
		if _deepest_row(reached) >= tower.rows - 1:
			return
		if not _carve_one(tower, reached):
			return
	push_warning("TowerBuilder: gave up forcing a descent route after %d carves" % MAX_CARVES)


func _flood_from_top(tower: TowerData) -> Dictionary:
	var reached: Dictionary = {}
	var queue: Array[Vector2i] = []
	for col in cols:
		var start := Vector2i(col, 0)
		if not tower.is_blocked(start):
			reached[start] = true
			queue.append(start)

	var head := 0
	while head < queue.size():
		var at := queue[head]
		head += 1
		for dir in TowerData.DIRS:
			var next := tower.wrap_pos(at + dir)
			if reached.has(next) or not tower.can_player_enter(at, next):
				continue
			reached[next] = true
			queue.append(next)
	return reached


func _deepest_row(reached: Dictionary) -> int:
	var deepest := -1
	for pos: Vector2i in reached:
		deepest = maxi(deepest, pos.y)
	return deepest


func _carve_one(tower: TowerData, reached: Dictionary) -> bool:
	var frontier_row := _deepest_row(reached)
	if frontier_row < 0 or frontier_row >= tower.rows - 1:
		return false
	var target_row := frontier_row + 1

	var rubble := Vector2i(-1, -1)
	var stone := Vector2i(-1, -1)
	for col in cols:
		var candidate := Vector2i(col, target_row)
		if reached.has(candidate) or not reached.has(Vector2i(col, frontier_row)):
			continue
		if tower.at(candidate).kind == Cell.Kind.WINDOW:
			continue
		if tower.at(candidate).blocked:
			rubble = candidate
			break
		if stone.x < 0:
			stone = candidate

	var victim := rubble if rubble.x >= 0 else stone
	if victim.x < 0:
		return false
	_open_cell(tower, victim)
	return true
