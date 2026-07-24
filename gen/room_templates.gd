class_name RoomTemplates extends RefCounted


enum Band { UPPER, MIDDLE, LOWER }

const WIDTH := Tuning.ROOM_W
const HEIGHT := Tuning.ROOM_H

const LEGEND := {
	".": {"kind": -1, "bars": 0, "anchor": ""},
	",": {"kind": -1, "bars": 0, "anchor": "creature"},
	"A": {"kind": -1, "bars": 0, "anchor": "altar"},
	"T": {"kind": Cell.Kind.WINDOW, "bars": Cell.BAR_TOP, "anchor": ""},
	"t": {"kind": Cell.Kind.WINDOW, "bars": Cell.BAR_TOP, "anchor": "creature"},
	"U": {"kind": Cell.Kind.WINDOW, "bars": Cell.BAR_TOP, "anchor": ""},
	"u": {"kind": Cell.Kind.WINDOW, "bars": Cell.BAR_TOP, "anchor": "creature"},
	"G": {"kind": Cell.Kind.WINDOW, "bars": Cell.BAR_TOP, "anchor": ""},
	"L": {"kind": Cell.Kind.LEDGE, "bars": Cell.BAR_TOP, "anchor": ""},
	"l": {"kind": Cell.Kind.LEDGE, "bars": Cell.BAR_TOP, "anchor": "creature"},
	"S": {"kind": Cell.Kind.LEDGE, "bars": Cell.BAR_BOTTOM, "anchor": ""},
	"s": {"kind": Cell.Kind.LEDGE, "bars": Cell.BAR_BOTTOM, "anchor": "creature"},
	"I": {"kind": Cell.Kind.PILASTER, "bars": Cell.BAR_LEFT, "anchor": ""},
	"i": {"kind": Cell.Kind.PILASTER, "bars": Cell.BAR_LEFT, "anchor": "creature"},
	"J": {"kind": Cell.Kind.PILASTER, "bars": Cell.BAR_RIGHT, "anchor": ""},
	"j": {"kind": Cell.Kind.PILASTER, "bars": Cell.BAR_RIGHT, "anchor": "creature"},
}

const WINDOW_GLYPHS := {
	"T": Vector2i(1, 2),
	"t": Vector2i(1, 2),
	"U": Vector2i(1, 2),
	"u": Vector2i(1, 2),
	"G": Vector2i(3, 5),
}


static func window_size(symbol: String) -> Vector2i:
	return WINDOW_GLYPHS.get(symbol, Vector2i.ZERO)


static func glyph_at(rows: Array, x: int, y: int) -> String:
	if y < 0 or y >= rows.size():
		return ""
	var row: String = rows[y]
	if x < 0 or x >= row.length():
		return ""
	return row[x]


static func bars_at(rows: Array, x: int, y: int) -> int:
	var glyph := glyph_at(rows, x, y)
	var spec := cell_for(glyph)
	if spec["kind"] != Cell.Kind.WINDOW:
		return spec["bars"]
	return 0 if glyph_at(rows, x, y - 1) == glyph else spec["bars"]


static func is_window_origin(rows: Array, x: int, y: int) -> bool:
	var glyph := glyph_at(rows, x, y)
	if window_size(glyph) == Vector2i.ZERO:
		return false
	return glyph_at(rows, x, y - 1) != glyph and glyph_at(rows, x - 1, y) != glyph


const UPPER: Array = [
	[
		".....",
		".TUT.",
		".TUT.",
		".SSS.",
		".....",
		".....",
		"..t..",
		"..t..",
		"..S..",
		".....",
	],
	[
		".....",
		".....",
		".LLL.",
		".....",
		".....",
		",....",
		".....",
		".LLL.",
		".....",
		".....",
	],
	[
		".....",
		".TUT.",
		".TUT.",
		".SSS.",
		".....",
		".LLL.",
		".....",
		".lA..",
		".....",
		".....",
	],
	[
		".....",
		".....",
		".....",
		".LLL.",
		".....",
		".....",
		".....",
		".T.T.",
		".T.T.",
		".S.S.",
	],
	[
		".....",
		".....",
		"..,..",
		".....",
		"I...J",
		"I...J",
		".....",
		"..T..",
		"..T..",
		"..S..",
	],
]


const MIDDLE: Array = [
	[
		".....",
		"..t..",
		"..t..",
		".LSL.",
		".....",
		".....",
		".LLL.",
		".....",
		"..A..",
		".....",
	],
	[
		".....",
		".GGG.",
		".GGG.",
		".GGG.",
		".GGG.",
		".GGG.",
		".SSS.",
		".....",
		",....",
		".....",
	],
	[
		".....",
		".....",
		".....",
		".JTI.",
		"..T..",
		"..S..",
		".....",
		".....",
		".....",
		".....",
	],
	[
		".....",
		".....",
		".LLL.",
		".....",
		".LLl.",
		"..T..",
		"..T..",
		"..S..",
		".....",
		".....",
	],
	[
		".....",
		"I...J",
		".....",
		".....",
		"..i..",
		".....",
		".LLL.",
		"..T..",
		"..T..",
		"..S..",
	],
]


const LOWER: Array = [
	[
		".....",
		"..I..",
		"..i..",
		".....",
		".....",
		".....",
		".....",
		".....",
		".....",
		".....",
	],
	[
		".....",
		".LLL.",
		".....",
		".....",
		".....",
		".....",
		".....",
		".,...",
		".LLL.",
		".....",
	],
	[
		".....",
		".....",
		"..T..",
		"..T..",
		"..S..",
		".....",
		".lLL.",
		".....",
		".....",
		".....",
	],
	[
		".....",
		".....",
		".LLL.",
		".....",
		".....",
		".....",
		".....",
		".....",
		".L.l.",
		"..A..",
	],
	[
		".....",
		"L...L",
		".....",
		".LLL.",
		".....",
		".....",
		".LLL.",
		".....",
		".....",
		"...,.",
	],
]


static var _validated := false


static func ensure_valid() -> void:
	if _validated:
		return
	_validated = true
	for problem in validate():
		push_error("RoomTemplates: %s" % problem)


static func pool_for(band: int) -> Array:
	match band:
		Band.UPPER:
			return UPPER
		Band.MIDDLE:
			return MIDDLE
		_:
			return LOWER


static func band_for(room_row: int, rooms_tall: int) -> int:
	var third := maxi(1, rooms_tall / 3)
	if room_row < third:
		return Band.UPPER
	if room_row < third * 2:
		return Band.MIDDLE
	return Band.LOWER


const MIRROR_FLIP := {"I": "J", "J": "I", "i": "j", "j": "i"}


static func mirrored(rows: Array) -> Array:
	var flipped: Array = []
	for row: String in rows:
		var reversed := row.reverse()
		var out := ""
		for i in reversed.length():
			out += MIRROR_FLIP.get(reversed[i], reversed[i])
		flipped.append(out)
	return flipped


static func cell_for(symbol: String) -> Dictionary:
	return LEGEND.get(symbol, LEGEND["."])


static func validate() -> PackedStringArray:
	var problems := PackedStringArray()
	for band in [Band.UPPER, Band.MIDDLE, Band.LOWER]:
		var pool := pool_for(band)
		for index in pool.size():
			var rows: Array = pool[index]
			if rows.size() != HEIGHT:
				problems.append("band %d room %d has %d rows, expected %d"
					% [band, index, rows.size(), HEIGHT])
				continue
			for row_index in rows.size():
				var row: String = rows[row_index]
				if row.length() != WIDTH:
					problems.append("band %d room %d row %d is %d wide, expected %d"
						% [band, index, row_index, row.length(), WIDTH])
				for i in row.length():
					if not LEGEND.has(row[i]):
						problems.append("band %d room %d row %d: unknown symbol '%s'"
							% [band, index, row_index, row[i]])
			_validate_windows(rows, band, index, problems)
	return problems


static func _validate_windows(rows: Array, band: int, index: int,
		problems: PackedStringArray) -> void:
	for symbol: String in WINDOW_GLYPHS:
		var size: Vector2i = WINDOW_GLYPHS[symbol]
		var count := 0
		var blocks := 0
		for y in rows.size():
			var row: String = rows[y]
			for x in row.length():
				if row[x] != symbol:
					continue
				count += 1
				if not is_window_origin(rows, x, y):
					continue
				blocks += 1
				if x + size.x > WIDTH or y + size.y > HEIGHT:
					problems.append("band %d room %d: %s window at (%d,%d) runs off the room"
						% [band, index, symbol, x, y])
					continue
				for dy in size.y:
					for dx in size.x:
						if glyph_at(rows, x + dx, y + dy) != symbol:
							problems.append(
								"band %d room %d: %s window at (%d,%d) is not a full %dx%d block"
								% [band, index, symbol, x, y, size.x, size.y])
		if count != blocks * size.x * size.y:
			problems.append("band %d room %d: %d %s cells do not tile into whole windows"
				% [band, index, count, symbol])


static func caster_stats() -> Dictionary:
	var casters := 0
	var rooms := 0
	var edges: Dictionary = {}
	var windows := 0
	for band in [Band.UPPER, Band.MIDDLE, Band.LOWER]:
		for rows in pool_for(band):
			rooms += 1
			for y in rows.size():
				var row: String = rows[y]
				for x in row.length():
					var spec := cell_for(row[x])
					var bars := bars_at(rows, x, y)
					if bars != 0:
						casters += 1
						edges[bars] = edges.get(bars, 0) + 1
					if spec["kind"] == Cell.Kind.WINDOW:
						windows += 1
	return {
		"rooms": rooms,
		"casters_per_room": float(casters) / float(maxi(1, rooms)),
		"windows_per_room": float(windows) / float(maxi(1, rooms)),
		"edges": edges,
	}
