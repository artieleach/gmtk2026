class_name RoomTemplates extends RefCounted


enum Band { UPPER, MIDDLE, LOWER }

const WIDTH := Tuning.ROOM_W
const HEIGHT := Tuning.ROOM_H

const LEGEND := {
	".": {"kind": -1, "depth": 0, "anchor": ""},
	",": {"kind": -1, "depth": 0, "anchor": "creature"},
	"A": {"kind": -1, "depth": 0, "anchor": "altar"},
	"W": {"kind": Cell.Kind.WINDOW, "depth": 1, "anchor": ""},
	"w": {"kind": Cell.Kind.WINDOW, "depth": 1, "anchor": "creature"},
	"L": {"kind": Cell.Kind.LEDGE, "depth": 1, "anchor": ""},
	"l": {"kind": Cell.Kind.LEDGE, "depth": 1, "anchor": "creature"},
	"E": {"kind": Cell.Kind.LEDGE, "depth": 2, "anchor": ""},
	"e": {"kind": Cell.Kind.LEDGE, "depth": 2, "anchor": "creature"},
	"C": {"kind": Cell.Kind.CORNICE, "depth": 3, "anchor": ""},
	"c": {"kind": Cell.Kind.CORNICE, "depth": 3, "anchor": "creature"},
}


const UPPER: Array = [
	[
		".....",
		".WWW.",
		".....",
		".L.L.",
		".....",
		"..w..",
		".....",
		".EEE.",
		".....",
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
		".EEE.",
		".....",
		".....",
	],
	[
		".....",
		".W.W.",
		".L.L.",
		".....",
		".EEE.",
		".....",
		".lAl.",
		".....",
		".....",
		".....",
	],
	[
		".....",
		".....",
		".....",
		"..C..",
		".....",
		".....",
		".....",
		".W.W.",
		".....",
		"..L..",
	],
	[
		".....",
		".....",
		"..,..",
		".....",
		".L.L.",
		".....",
		".....",
		"..E..",
		".....",
		"..W..",
	],
]


const MIDDLE: Array = [
	[
		".....",
		"..w..",
		".....",
		".E.E.",
		".....",
		".....",
		"..L..",
		".....",
		"..A..",
		".....",
	],
	[
		".....",
		".W.W.",
		".....",
		".L.L.",
		".....",
		".....",
		",....",
		".....",
		".....",
		".....",
	],
	[
		"L...L",
		".....",
		"..W..",
		".....",
		"..E..",
		".....",
		".....",
		".....",
		".....",
		".....",
	],
	[
		".....",
		".....",
		".LLl.",
		".....",
		".....",
		"..W..",
		".....",
		".....",
		".....",
		".....",
	],
	[
		".....",
		".L.L.",
		".....",
		".....",
		"..,..",
		".....",
		"..E..",
		".....",
		".....",
		"..W..",
	],
]


const LOWER: Array = [
	[
		".....",
		".L.L.",
		".....",
		".....",
		"..E..",
		".....",
		".....",
		"..e..",
		".....",
		".....",
	],
	[
		".....",
		".E.E.",
		".....",
		".....",
		".....",
		".....",
		".....",
		".,...",
		".L.L.",
		".....",
	],
	[
		".....",
		".....",
		"..W..",
		"..L..",
		".....",
		".....",
		"l...L",
		".....",
		".....",
		".....",
	],
	[
		".....",
		".....",
		"..C..",
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
		"..E..",
		".....",
		".....",
		"..L..",
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


static func mirrored(rows: Array) -> Array:
	var flipped: Array = []
	for row: String in rows:
		flipped.append(row.reverse())
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
	return problems


static func caster_stats() -> Dictionary:
	var casters := 0
	var rooms := 0
	var depths: Dictionary = {}
	var windows := 0
	for band in [Band.UPPER, Band.MIDDLE, Band.LOWER]:
		for rows in pool_for(band):
			rooms += 1
			for row: String in rows:
				for i in row.length():
					var spec := cell_for(row[i])
					if spec["depth"] > 0:
						casters += 1
						depths[spec["depth"]] = depths.get(spec["depth"], 0) + 1
					if spec["kind"] == Cell.Kind.WINDOW:
						windows += 1
	return {
		"rooms": rooms,
		"casters_per_room": float(casters) / float(maxi(1, rooms)),
		"windows_per_room": float(windows) / float(maxi(1, rooms)),
		"depths": depths,
	}
