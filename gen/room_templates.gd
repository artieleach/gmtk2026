class_name RoomTemplates extends RefCounted


enum Band { UPPER, MIDDLE, LOWER }

const WIDTH := Tuning.ROOM_W
const HEIGHT := Tuning.ROOM_H

const ROUTE_ENTRY_FRAME_ROWS := 2
const ROUTE_LOWER_MIN_LIDS := 3
const WALL_MIN_SHOULDER := 2
const COURSE_ROWS: Array[int] = [4]

const WALL_W := WIDTH * 2 + 1
const WALL_H := HEIGHT * 2 + 1

const OBJECTS := {
	".": {"anchor": "", "route": false, "kind": -1},
	",": {"anchor": "creature", "route": false, "kind": -1},
	"A": {"anchor": "altar", "route": false, "kind": -1},
	"o": {"anchor": "", "route": true, "kind": -1},
	"T": {"anchor": "", "route": false, "kind": Cell.Kind.WINDOW},
	"U": {"anchor": "", "route": false, "kind": Cell.Kind.WINDOW},
	"G": {"anchor": "", "route": false, "kind": Cell.Kind.WINDOW},
}

const WINDOW_GLYPHS := {
	"T": Vector2i(1, 2),
	"U": Vector2i(1, 2),
	"G": Vector2i(3, 5),
}


static func window_size(symbol: String) -> Vector2i:
	return WINDOW_GLYPHS.get(symbol, Vector2i.ZERO)


static func is_lane(symbol: String) -> bool:
	return OBJECTS.get(symbol, OBJECTS["."])["route"]


static func route_face(room_row: int, start_face: int) -> int:
	return wrapi(start_face + room_row, 0, Tuning.FACES)


static func glyph_at(rows: Array, x: int, y: int) -> String:
	if y < 0 or y >= rows.size():
		return ""
	var row: String = rows[y]
	if x < 0 or x >= row.length():
		return ""
	return row[x]


static func wall_above(walls: Array, x: int, y: int) -> bool:
	return glyph_at(walls, x * 2 + 1, y * 2) == "-"


static func wall_left(walls: Array, x: int, y: int) -> bool:
	return glyph_at(walls, x * 2, y * 2 + 1) == "|"


static func bars_at(walls: Array, x: int, y: int) -> int:
	var bars := 0
	if wall_above(walls, x, y):
		bars |= Cell.BAR_TOP
	if wall_left(walls, x, y):
		bars |= Cell.BAR_LEFT
	if y == HEIGHT - 1 and wall_above(walls, x, HEIGHT):
		bars |= Cell.BAR_BOTTOM
	if x == WIDTH - 1 and wall_left(walls, WIDTH, y):
		bars |= Cell.BAR_RIGHT
	return bars


static func apply_cell(tower: TowerData, pos: Vector2i, walls: Array, objects: Array,
		x: int, y: int) -> String:
	var spec: Dictionary = OBJECTS.get(glyph_at(objects, x, y), OBJECTS["."])
	var cell := tower.at(pos)
	cell.bars = bars_at(walls, x, y)
	cell.route = spec["route"]
	if spec["kind"] != -1:
		cell.kind = spec["kind"]
	elif cell.bars & (Cell.BAR_TOP | Cell.BAR_BOTTOM) != 0:
		cell.kind = Cell.Kind.LEDGE
	elif cell.bars & (Cell.BAR_LEFT | Cell.BAR_RIGHT) != 0:
		cell.kind = Cell.Kind.PILASTER
	return spec["anchor"]


static func is_window_origin(objects: Array, x: int, y: int) -> bool:
	var glyph := glyph_at(objects, x, y)
	if window_size(glyph) == Vector2i.ZERO:
		return false
	return glyph_at(objects, x, y - 1) != glyph and glyph_at(objects, x - 1, y) != glyph


const ROUTE_UPPER: Array = [
	{
		"walls": [
			"+.+.+.+.+-+",
			"...........",
			"+.+.+.+.+.+",
			"....|......",
			"+.+.+.+.+.+",
			"......|....",
			"+.+.+.+.+.+",
			"........|..",
			"+-+-+-+-+.+",
			"...........",
			"+.+-+-+-+-+",
			"...........",
			"+.+.+.+.+.+",
			"..|........",
			"+.+.+.+.+.+",
			"....|......",
			"+.+.+.+.+.+",
			"......|....",
			"+.+.+.+.+.+",
			"........|..",
			"+.+.+.+.+.+",
		],
		"objects": [
			"oo..T",
			"..o.T",
			"...o.",
			"....o",
			".ooo.",
			"o....",
			".o...",
			"..o..",
			"...o.",
			"....o",
		],
	},
	{
		"walls": [
			"+.+-+.+.+.+",
			"...........",
			"+.+.+.+.+.+",
			"....|......",
			"+.+.+.+.+.+",
			"......|....",
			"+.+.+.+.+.+",
			"........|..",
			"+-+-+-+-+.+",
			"...........",
			"+.+-+-+-+-+",
			"...........",
			"+.+.+.+.+.+",
			"..|........",
			"+.+.+.+.+.+",
			"....|......",
			"+.+.+.+.+.+",
			"......|....",
			"+.+.+.+.+.+",
			"........|..",
			"+.+.+.+.+.+",
		],
		"objects": [
			"oo...",
			"..o..",
			"...o.",
			"....o",
			".ooo.",
			"o....",
			".o...",
			"..o..",
			"...o.",
			"....o",
		],
	},
	{
		"walls": [
			"+.+.+.+.+.+",
			"...........",
			"+.+.+.+.+.+",
			"..|........",
			"+.+.+.+.+.+",
			"....|......",
			"+.+.+.+.+.+",
			"......|....",
			"+-+-+-+.+-+",
			"...........",
			"+.+-+-+-+-+",
			"...........",
			"+.+.+.+.+.+",
			"..|........",
			"+.+.+.+.+.+",
			"....|......",
			"+-+-+.+.+.+",
			"......|....",
			"+.+.+.+.+.+",
			"........|..",
			"+.+.+.+.+.+",
		],
		"objects": [
			"o....",
			".o...",
			"..o..",
			"...o.",
			".oo..",
			"o....",
			".o...",
			"..o..",
			"...o.",
			"....o",
		],
	},
	{
		"walls": [
			"+.+.+.+.+.+",
			"...........",
			"+.+.+.+.+.+",
			"..|........",
			"+.+.+.+.+.+",
			"....|......",
			"+.+.+.+.+.+",
			"......|....",
			"+-+-+-+.+-+",
			"...........",
			"+.+-+-+-+-+",
			"...........",
			"+.+.+.+.+.+",
			"..|........",
			"+.+.+.+.+-+",
			"....|......",
			"+.+.+.+.+.+",
			"......|....",
			"+.+.+.+.+.+",
			"........|..",
			"+.+.+.+.+.+",
		],
		"objects": [
			"o....",
			".o...",
			"..o..",
			"...o.",
			".oo..",
			"o....",
			".o...",
			"..o.T",
			"...oT",
			"....o",
		],
	},
	{
		"walls": [
			"+.+-+.+.+.+",
			"...........",
			"+.+.+.+.+.+",
			"....|......",
			"+.+.+.+.+.+",
			"......|....",
			"+.+.+.+.+.+",
			"........|..",
			"+-+-+-+-+.+",
			"...........",
			"+.+-+-+-+-+",
			"...........",
			"+.+.+.+.+.+",
			"..|........",
			"+.+.+.+.+.+",
			"....|......",
			"+-+.+.+.+.+",
			"......|....",
			"+.+.+.+.+.+",
			"........|..",
			"+.+.+.+.+.+",
		],
		"objects": [
			"oo...",
			"..o..",
			"...o.",
			"....o",
			".ooo.",
			"o....",
			".o...",
			"..o..",
			"...o.",
			"....o",
		],
	},
	{
		"walls": [
			"+.+.+.+.+-+",
			"...........",
			"+.+.+.+.+.+",
			"..|........",
			"+.+.+.+.+.+",
			"....|......",
			"+.+.+.+.+.+",
			"......|....",
			"+-+-+-+.+-+",
			"...........",
			"+.+-+-+-+-+",
			"...........",
			"+.+.+.+.+.+",
			"..|........",
			"+.+.+.+.+.+",
			"....|......",
			"+-+.+.+.+.+",
			"......|....",
			"+.+.+.+.+.+",
			"........|..",
			"+.+.+.+.+.+",
		],
		"objects": [
			"o...T",
			".o..T",
			"..o..",
			"...o.",
			".oo..",
			"o....",
			".o...",
			"..o..",
			"...o.",
			"....o",
		],
	},
]


const ROUTE_MIDDLE: Array = [
	{
		"walls": [
			"+.+.+.+.+-+",
			"...........",
			"+.+.+.+.+.+",
			"....|......",
			"+.+.+.+.+.+",
			"......|....",
			"+.+.+.+.+.+",
			"........|..",
			"+-+-+-+-+.+",
			"...........",
			"+.+-+-+-+-+",
			"...........",
			"+.+.+.+.+.+",
			"..|........",
			"+.+.+.+.+.+",
			"....|......",
			"+.+.+.+.+.+",
			"......|....",
			"+.+.+.+.+.+",
			"........|..",
			"+.+.+.+.+.+",
		],
		"objects": [
			"oo..T",
			"..o.T",
			"...o.",
			"....o",
			".ooo.",
			"o....",
			".o...",
			"..o..",
			"...o.",
			"..A.o",
		],
	},
	{
		"walls": [
			"+.+-+.+.+.+",
			"...........",
			"+.+.+.+.+.+",
			"....|......",
			"+.+.+.+.+.+",
			"......|....",
			"+.+.+.+.+.+",
			"........|..",
			"+-+-+-+-+.+",
			"...........",
			"+.+-+-+-+-+",
			"...........",
			"+.+.+.+.+.+",
			"..|........",
			"+.+.+.+.+.+",
			"....|......",
			"+.+.+.+.+.+",
			"......|....",
			"+.+.+.+.+.+",
			"........|..",
			"+.+.+.+.+.+",
		],
		"objects": [
			"oo...",
			"..o..",
			"...o.",
			"....o",
			".ooo.",
			"o....",
			".o...",
			"..o..",
			"...o.",
			",...o",
		],
	},
	{
		"walls": [
			"+.+.+.+.+.+",
			"...........",
			"+.+.+.+.+.+",
			"..|........",
			"+.+.+.+.+.+",
			"....|......",
			"+.+.+.+.+.+",
			"......|....",
			"+-+-+-+.+-+",
			"...........",
			"+.+-+-+-+-+",
			"...........",
			"+.+.+.+.+.+",
			"..|........",
			"+.+.+.+.+.+",
			"....|......",
			"+-+-+.+.+.+",
			"......|....",
			"+.+.+.+.+.+",
			"........|..",
			"+.+.+.+.+.+",
		],
		"objects": [
			"o....",
			".o...",
			"..o..",
			"...o.",
			".oo..",
			"o....",
			".o...",
			"..o..",
			".,.o.",
			"....o",
		],
	},
	{
		"walls": [
			"+.+.+.+.+.+",
			"...........",
			"+.+.+.+.+.+",
			"..|........",
			"+.+.+.+.+.+",
			"....|......",
			"+.+.+.+.+.+",
			"......|....",
			"+-+-+-+.+-+",
			"...........",
			"+.+-+-+-+-+",
			"...........",
			"+.+.+.+.+.+",
			"..|........",
			"+.+.+.+.+-+",
			"....|......",
			"+.+.+.+.+.+",
			"......|....",
			"+.+.+.+.+.+",
			"........|..",
			"+.+.+.+.+.+",
		],
		"objects": [
			"o....",
			".o...",
			"..o..",
			"...o.",
			".oo..",
			"o....",
			".o...",
			"..o.T",
			"...oT",
			"....o",
		],
	},
	{
		"walls": [
			"+.+-+.+.+.+",
			"...........",
			"+.+.+.+.+.+",
			"....|......",
			"+.+.+.+.+.+",
			"......|....",
			"+.+.+.+.+.+",
			"........|..",
			"+-+-+-+-+.+",
			"...........",
			"+.+-+-+-+-+",
			"...........",
			"+.+.+.+.+.+",
			"..|........",
			"+.+.+.+.+.+",
			"....|......",
			"+-+.+.+.+.+",
			"......|....",
			"+.+.+.+.+.+",
			"........|..",
			"+.+.+.+.+.+",
		],
		"objects": [
			"oo...",
			"..o..",
			"...o.",
			"....o",
			".ooo.",
			"o....",
			".o...",
			"..o..",
			"...o.",
			"..A.o",
		],
	},
	{
		"walls": [
			"+.+.+.+.+-+",
			"...........",
			"+.+.+.+.+.+",
			"..|........",
			"+.+.+.+.+.+",
			"....|......",
			"+.+.+.+.+.+",
			"......|....",
			"+-+-+-+.+-+",
			"...........",
			"+.+-+-+-+-+",
			"...........",
			"+.+.+.+.+.+",
			"..|........",
			"+.+.+.+.+.+",
			"....|......",
			"+-+.+.+.+.+",
			"......|....",
			"+.+.+.+.+.+",
			"........|..",
			"+.+.+.+.+.+",
		],
		"objects": [
			"o...T",
			".o..T",
			"..o..",
			"...o.",
			".oo..",
			"o....",
			".o...",
			"..o..",
			",..o.",
			"....o",
		],
	},
]


const ROUTE_LOWER: Array = [
	{
		"walls": [
			"+.+-+.+.+.+",
			"...........",
			"+.+.+.+.+.+",
			"....|......",
			"+.+.+.+.+.+",
			"......|....",
			"+.+.+.+.+.+",
			"........|..",
			"+-+-+-+-+.+",
			"...........",
			"+.+-+-+-+-+",
			"...........",
			"+.+.+.+.+.+",
			"..|........",
			"+.+.+.+.+.+",
			"....|......",
			"+-+-+.+.+.+",
			"......|....",
			"+.+.+.+.+.+",
			"........|..",
			"+.+.+.+.+.+",
		],
		"objects": [
			"oo...",
			"..o..",
			"...o.",
			"....o",
			".ooo.",
			"o....",
			".o...",
			"..o..",
			"...o.",
			"....o",
		],
	},
	{
		"walls": [
			"+.+-+.+.+.+",
			"...........",
			"+.+.+.+.+.+",
			"....|......",
			"+.+.+.+.+.+",
			"......|....",
			"+.+.+.+.+.+",
			"........|..",
			"+-+-+-+-+.+",
			"...........",
			"+.+-+-+-+-+",
			"...........",
			"+.+.+.+.+.+",
			"..|........",
			"+-+.+.+.+.+",
			"....|......",
			"+.+.+.+.+.+",
			"......|....",
			"+.+.+.+.+.+",
			"........|..",
			"+.+.+.+.+.+",
		],
		"objects": [
			"oo...",
			"..o..",
			"...o.",
			"....o",
			".ooo.",
			"o....",
			".o...",
			"..o..",
			"...o.",
			"....o",
		],
	},
	{
		"walls": [
			"+.+.+.+.+.+",
			"...........",
			"+.+.+.+.+.+",
			"..|........",
			"+.+.+.+.+.+",
			"....|......",
			"+.+.+.+.+.+",
			"......|....",
			"+-+-+-+.+-+",
			"...........",
			"+.+-+-+-+-+",
			"...........",
			"+.+.+.+.+.+",
			"..|........",
			"+.+.+.+.+.+",
			"....|......",
			"+-+-+.+.+.+",
			"......|....",
			"+.+.+.+.+.+",
			"........|..",
			"+.+.+.+.+.+",
		],
		"objects": [
			"o....",
			".o...",
			"..o..",
			"...o.",
			".oo..",
			"o....",
			".o...",
			"..o..",
			"...o.",
			"....o",
		],
	},
	{
		"walls": [
			"+.+.+.+.+.+",
			"...........",
			"+.+.+.+.+.+",
			"..|........",
			"+.+.+.+.+.+",
			"....|......",
			"+.+.+.+.+.+",
			"......|....",
			"+-+-+-+.+-+",
			"...........",
			"+.+-+-+-+-+",
			"...........",
			"+.+.+.+.+.+",
			"..|........",
			"+-+.+.+.+.+",
			"....|......",
			"+.+.+.+.+.+",
			"......|....",
			"+.+.+.+.+.+",
			"........|..",
			"+.+.+.+.+.+",
		],
		"objects": [
			"o....",
			".o...",
			"..o..",
			"...o.",
			".oo..",
			"o....",
			".o...",
			"..o..",
			"...o.",
			"....o",
		],
	},
	{
		"walls": [
			"+.+-+.+.+.+",
			"...........",
			"+.+.+.+.+.+",
			"....|......",
			"+.+.+.+.+.+",
			"......|....",
			"+.+.+.+.+.+",
			"........|..",
			"+-+-+-+-+.+",
			"...........",
			"+.+-+-+-+-+",
			"...........",
			"+.+.+.+.+.+",
			"..|........",
			"+.+.+.+.+.+",
			"....|......",
			"+-+-+.+.+.+",
			"......|....",
			"+.+.+.+.+.+",
			"........|..",
			"+.+.+.+.+.+",
		],
		"objects": [
			"oo...",
			"..o..",
			"...o.",
			"....o",
			".ooo.",
			"o....",
			".o...",
			"..o..",
			"...o.",
			"....o",
		],
	},
	{
		"walls": [
			"+.+.+.+.+.+",
			"...........",
			"+-+.+.+.+.+",
			"....|......",
			"+.+.+.+.+.+",
			"....|......",
			"+.+.+.+.+.+",
			"......|....",
			"+-+-+-+.+-+",
			"...........",
			"+.+-+-+-+-+",
			"...........",
			"+.+.+.+.+.+",
			"..|........",
			"+.+.+.+.+.+",
			"....|......",
			"+-+-+.+.+.+",
			"......|....",
			"+.+.+.+.+.+",
			"........|..",
			"+.+.+.+.+.+",
		],
		"objects": [
			"oo...",
			"..o..",
			"..o..",
			"...o.",
			".oo..",
			"o....",
			".o...",
			"..o..",
			",..o.",
			"....o",
		],
	},
]


const WALL_UPPER: Array = [
	{
		"walls": [
			"+.+.+-+-+.+",
			"...........",
			"+.+.+.+.+.+",
			"...........",
			"+.+.+.+.+.+",
			"...........",
			"+.+.+.+.+.+",
			"...........",
			"+-+-+-+-+-+",
			"...........",
			"+-+-+-+-+-+",
			"...........",
			"+.+.+.+.+.+",
			"...........",
			"+.+-+.+-+.+",
			"...........",
			"+.+.+.+.+.+",
			"...........",
			"+.+.+.+.+.+",
			"...........",
			"+.+.+.+.+.+",
		],
		"objects": [
			".....",
			".....",
			".....",
			".....",
			".....",
			".....",
			".....",
			".T.T.",
			".T.T.",
			"..,..",
		],
	},
	{
		"walls": [
			"+.+.+.+.+.+",
			"|.........|",
			"+.+.+.+.+.+",
			"|.........|",
			"+.+.+.+.+.+",
			"|.........|",
			"+.+.+.+.+.+",
			"...........",
			"+-+-+-+-+-+",
			"...........",
			"+-+-+-+-+-+",
			"...........",
			"+.+.+.+.+.+",
			"...........",
			"+.+.+.+.+.+",
			"...........",
			"+.+.+.+.+.+",
			"...........",
			"+.+.+.+.+.+",
			"...........",
			"+.+.+.+.+.+",
		],
		"objects": [
			".....",
			".....",
			".....",
			".....",
			".....",
			".....",
			".....",
			".....",
			".....",
			"..,..",
		],
	},
	{
		"walls": [
			"+.+-+-+-+.+",
			"...........",
			"+.+.+.+.+.+",
			"...........",
			"+.+.+.+.+.+",
			"...........",
			"+.+.+.+.+.+",
			"...........",
			"+-+-+-+-+-+",
			"...........",
			"+-+-+-+-+-+",
			"...........",
			"+.+.+.+.+.+",
			"...........",
			"+.+.+-+-+.+",
			"...........",
			"+.+.+.+.+.+",
			"...........",
			"+.+.+.+.+.+",
			"...........",
			"+.+.+.+.+.+",
		],
		"objects": [
			".T...",
			".T...",
			".....",
			".....",
			".....",
			".....",
			".....",
			".....",
			".....",
			",....",
		],
	},
	{
		"walls": [
			"+.+.+.+.+.+",
			"....|......",
			"+.+.+.+.+.+",
			"....|......",
			"+.+.+.+.+.+",
			"....|......",
			"+.+.+.+.+.+",
			"...........",
			"+-+-+-+-+-+",
			"...........",
			"+-+-+-+-+-+",
			"...........",
			"+.+.+.+.+.+",
			"...........",
			"+.+.+-+-+-+",
			"...........",
			"+.+.+.+.+.+",
			"...........",
			"+.+.+.+.+.+",
			"...........",
			"+.+.+.+.+.+",
		],
		"objects": [
			".....",
			".....",
			"..,..",
			".....",
			".....",
			".....",
			".....",
			".....",
			".....",
			".,...",
		],
	},
	{
		"walls": [
			"+.+.+-+-+.+",
			"...........",
			"+.+.+.+.+.+",
			"..........|",
			"+.+.+.+.+.+",
			"...........",
			"+.+.+.+.+.+",
			"...........",
			"+-+-+-+-+-+",
			"...........",
			"+-+-+-+-+-+",
			"...........",
			"+.+.+.+.+.+",
			"|..........",
			"+.+.+.+.+.+",
			"|..........",
			"+.+.+.+.+.+",
			"|..........",
			"+.+.+.+.+.+",
			"...........",
			"+.+.+.+.+.+",
		],
		"objects": [
			".....",
			".....",
			".....",
			".....",
			".....",
			".....",
			".....",
			".....",
			".....",
			"..,..",
		],
	},
	{
		"walls": [
			"+.+.+-+-+.+",
			"...........",
			"+.+.+.+.+.+",
			"...........",
			"+.+.+.+.+.+",
			"...........",
			"+.+.+.+.+.+",
			"...........",
			"+-+-+-+-+-+",
			"...........",
			"+-+-+-+-+-+",
			"...........",
			"+.+.+.+.+.+",
			"...........",
			"+.+-+.+.+.+",
			"...........",
			"+.+.+-+-+.+",
			"...........",
			"+.+.+.+.+.+",
			"...........",
			"+.+.+.+.+.+",
		],
		"objects": [
			".....",
			".....",
			".....",
			".....",
			".....",
			".....",
			".....",
			".T...",
			".T...",
			",....",
		],
	},
]

const WALL_MIDDLE: Array = [
	{
		"walls": [
			"+.+.+-+-+.+",
			"...........",
			"+.+.+.+.+.+",
			"...........",
			"+.+.+.+.+.+",
			"...........",
			"+.+.+.+.+.+",
			"...........",
			"+-+-+-+-+-+",
			"...........",
			"+-+-+-+-+-+",
			"...........",
			"+.+.+.+.+.+",
			"...........",
			"+.+-+.+-+.+",
			"...........",
			"+.+.+.+.+.+",
			"...........",
			"+.+.+.+.+.+",
			"...........",
			"+.+.+.+.+.+",
		],
		"objects": [
			".....",
			".....",
			".....",
			".....",
			".....",
			".....",
			".....",
			".T.T.",
			".T.T.",
			"..A..",
		],
	},
	{
		"walls": [
			"+.+.+.+.+.+",
			"|.........|",
			"+.+.+.+.+.+",
			"|.........|",
			"+.+.+.+.+.+",
			"|.........|",
			"+.+.+.+.+.+",
			"...........",
			"+-+-+-+-+-+",
			"...........",
			"+-+-+-+-+-+",
			"...........",
			"+.+.+.+.+.+",
			"...........",
			"+.+.+.+.+.+",
			"...........",
			"+.+.+.+.+.+",
			"...........",
			"+.+.+.+.+.+",
			"...........",
			"+.+.+.+.+.+",
		],
		"objects": [
			".....",
			".....",
			".....",
			".....",
			".....",
			".....",
			".....",
			".....",
			".....",
			"..,..",
		],
	},
	{
		"walls": [
			"+.+-+-+-+.+",
			"...........",
			"+.+.+.+.+.+",
			"...........",
			"+.+.+.+.+.+",
			"...........",
			"+.+.+.+.+.+",
			"...........",
			"+-+-+-+-+-+",
			"...........",
			"+-+-+-+-+-+",
			"...........",
			"+.+.+.+.+.+",
			"...........",
			"+.+.+-+-+.+",
			"...........",
			"+.+.+.+.+.+",
			"...........",
			"+.+.+.+.+.+",
			"...........",
			"+.+.+.+.+.+",
		],
		"objects": [
			".T,..",
			".T...",
			".....",
			".....",
			".....",
			".....",
			".....",
			".....",
			".....",
			",....",
		],
	},
	{
		"walls": [
			"+.+.+.+.+.+",
			"....|......",
			"+.+.+.+.+.+",
			"....|......",
			"+.+.+.+.+.+",
			"....|......",
			"+.+.+.+.+.+",
			"...........",
			"+-+-+-+-+-+",
			"...........",
			"+-+-+-+-+-+",
			"...........",
			"+.+.+.+.+.+",
			"...........",
			"+.+.+-+-+-+",
			"...........",
			"+.+.+.+.+.+",
			"...........",
			"+.+.+.+.+.+",
			"...........",
			"+.+.+.+.+.+",
		],
		"objects": [
			".....",
			".....",
			"..,..",
			".....",
			".....",
			".....",
			".....",
			".....",
			".....",
			".A...",
		],
	},
	{
		"walls": [
			"+.+.+-+-+.+",
			"...........",
			"+.+.+.+.+.+",
			"..........|",
			"+.+.+.+.+.+",
			"...........",
			"+.+.+.+.+.+",
			"...........",
			"+-+-+-+-+-+",
			"...........",
			"+-+-+-+-+-+",
			"...........",
			"+.+.+.+.+.+",
			"|..........",
			"+.+.+.+.+.+",
			"|..........",
			"+.+.+.+.+.+",
			"|..........",
			"+.+.+.+.+.+",
			"...........",
			"+.+.+.+.+.+",
		],
		"objects": [
			".....",
			".....",
			".....",
			".....",
			".....",
			".....",
			".....",
			".....",
			".....",
			"..,..",
		],
	},
	{
		"walls": [
			"+.+.+-+-+.+",
			"...........",
			"+.+.+.+.+.+",
			"...........",
			"+.+.+.+.+.+",
			"...........",
			"+.+.+.+.+.+",
			"...........",
			"+-+-+-+-+-+",
			"...........",
			"+-+-+-+-+-+",
			"...........",
			"+.+.+.+.+.+",
			"...........",
			"+.+-+.+.+.+",
			"...........",
			"+.+.+-+-+.+",
			"...........",
			"+.+.+.+.+.+",
			"...........",
			"+.+.+.+.+.+",
		],
		"objects": [
			".....",
			".....",
			".....",
			".....",
			".....",
			".....",
			".....",
			".T...",
			".T.,.",
			",....",
		],
	},
]

const WALL_LOWER: Array = [
	{
		"walls": [
			"+-+.+-+-+.+",
			"...........",
			"+.+.+.+-+.+",
			"...........",
			"+.+.+.+.+.+",
			"...........",
			"+.+.+.+.+.+",
			"...........",
			"+-+-+-+-+-+",
			"...........",
			"+-+-+-+-+-+",
			"...........",
			"+.+.+.+.+.+",
			"...........",
			"+.+-+-+.+.+",
			"...........",
			"+.+.+.+.+.+",
			"...........",
			"+.+.+.+.+.+",
			"...........",
			"+.+.+.+.+.+",
		],
		"objects": [
			".....",
			".....",
			".....",
			".....",
			".....",
			".....",
			".....",
			".....",
			".....",
			"...,.",
		],
	},
	{
		"walls": [
			"+.+.+-+-+.+",
			"|..........",
			"+.+.+.+.+.+",
			"|..........",
			"+.+.+.+.+.+",
			"|..........",
			"+.+.+.+.+.+",
			"...........",
			"+-+-+-+-+-+",
			"...........",
			"+-+-+-+-+-+",
			"...........",
			"+.+.+.+-+-+",
			"...........",
			"+.+.+.+.+.+",
			"...........",
			"+.+.+.+.+.+",
			"...........",
			"+.+.+.+.+.+",
			"...........",
			"+.+.+.+.+.+",
		],
		"objects": [
			".....",
			".....",
			".....",
			".....",
			".....",
			".....",
			".....",
			".....",
			".....",
			"..,..",
		],
	},
	{
		"walls": [
			"+-+.+-+-+.+",
			"...........",
			"+.+.+.+.+.+",
			"...........",
			"+.+.+.+.+.+",
			"...........",
			"+.+.+.+.+.+",
			"...........",
			"+-+-+-+-+-+",
			"...........",
			"+-+-+-+-+-+",
			"...........",
			"+.+.+.+.+.+",
			"...........",
			"+.+-+.+.+-+",
			"...........",
			"+.+.+.+.+.+",
			"...........",
			"+.+.+.+.+.+",
			"...........",
			"+.+.+.+.+.+",
		],
		"objects": [
			".....",
			".....",
			".....",
			".....",
			".....",
			".....",
			".....",
			".T...",
			".T...",
			".....",
		],
	},
	{
		"walls": [
			"+.+.+.+.+.+",
			"....|......",
			"+.+.+.+.+.+",
			"....|......",
			"+.+.+.+.+.+",
			"....|......",
			"+.+.+.+.+.+",
			"...........",
			"+-+-+-+-+-+",
			"...........",
			"+-+-+-+-+-+",
			"...........",
			"+.+.+.+.+.+",
			"...........",
			"+.+.+.+-+-+",
			"...........",
			"+.+.+.+.+.+",
			"...........",
			"+.+.+.+.+.+",
			"...........",
			"+.+.+.+.+.+",
		],
		"objects": [
			".....",
			".....",
			"..,..",
			".....",
			".....",
			".....",
			".....",
			".....",
			".....",
			".A...",
		],
	},
	{
		"walls": [
			"+-+-+.+.+.+",
			"...........",
			"+.+.+-+-+.+",
			"...........",
			"+.+.+.+.+.+",
			"...........",
			"+.+.+.+.+.+",
			"...........",
			"+-+-+-+-+-+",
			"...........",
			"+-+-+-+-+-+",
			"...........",
			"+.+.+.+.+.+",
			"...........",
			"+.+.+.+-+-+",
			"...........",
			"+.+.+.+.+.+",
			"...........",
			"+.+.+.+.+.+",
			"...........",
			"+.+.+.+.+.+",
		],
		"objects": [
			".....",
			".....",
			".....",
			".....",
			".....",
			".....",
			".....",
			".....",
			".....",
			"..,..",
		],
	},
	{
		"walls": [
			"+.+.+.+-+-+",
			"...........",
			"+-+-+.+.+.+",
			"...........",
			"+.+.+.+.+.+",
			"...........",
			"+.+.+.+.+.+",
			"...........",
			"+-+-+-+-+-+",
			"...........",
			"+-+-+-+-+-+",
			"...........",
			"+.+.+.+.+.+",
			"...........",
			"+-+-+.+.+.+",
			"...........",
			"+.+.+.+.+.+",
			"...........",
			"+.+.+.+.+.+",
			"...........",
			"+.+.+.+.+.+",
		],
		"objects": [
			".....",
			".....",
			".....",
			".....",
			".....",
			".....",
			".....",
			",....",
			".....",
			".....",
		],
	},
]


static var _validated := false


static func ensure_valid() -> void:
	if _validated:
		return
	_validated = true
	var problems := validate()
	for problem in problems:
		push_error("RoomTemplates: %s" % problem)
	assert(problems.is_empty(), "RoomTemplates: %d invalid template(s)" % problems.size())


static func wall_pool_for(band: int) -> Array:
	match band:
		Band.UPPER:
			return WALL_UPPER
		Band.MIDDLE:
			return WALL_MIDDLE
		_:
			return WALL_LOWER


static func route_pool_for(band: int) -> Array:
	match band:
		Band.UPPER:
			return ROUTE_UPPER
		Band.MIDDLE:
			return ROUTE_MIDDLE
		_:
			return ROUTE_LOWER


static func band_for(room_row: int, rooms_tall: int) -> int:
	var third := maxi(1, rooms_tall / 3)
	if room_row < third:
		return Band.UPPER
	if room_row < third * 2:
		return Band.MIDDLE
	return Band.LOWER


static func mirrored(room: Dictionary) -> Dictionary:
	var objects: Array = room["objects"]
	for row: String in objects:
		for i in row.length():
			if is_lane(row[i]):
				push_error("RoomTemplates.mirrored: refusing to flip a route room")
				return room
	var flipped_walls: Array = []
	for row: String in room["walls"]:
		flipped_walls.append(row.reverse())
	var flipped_objects: Array = []
	for row: String in objects:
		flipped_objects.append(row.reverse())
	return {"walls": flipped_walls, "objects": flipped_objects}


static func validate() -> PackedStringArray:
	var problems := PackedStringArray()
	for band in [Band.UPPER, Band.MIDDLE, Band.LOWER]:
		for entry in [["wall", wall_pool_for(band)], ["route", route_pool_for(band)]]:
			var kind: String = entry[0]
			var pool: Array = entry[1]
			for index in pool.size():
				var room: Dictionary = pool[index]
				var label := "band %d %s room %d" % [band, kind, index]
				if not _shaped(room, label, problems):
					continue
				_validate_windows(room["objects"], label, problems)
				if kind == "route":
					_validate_route(room, band, label, problems)
				else:
					_validate_wall(room, label, problems)
	return problems


static func _shaped(room: Dictionary, label: String, problems: PackedStringArray) -> bool:
	var ok := true
	if not room.has("walls") or not room.has("objects"):
		problems.append("%s is missing a layer" % label)
		return false
	var walls: Array = room["walls"]
	var objects: Array = room["objects"]
	if walls.size() != WALL_H:
		problems.append("%s: wall grid has %d rows, expected %d" % [label, walls.size(), WALL_H])
		ok = false
	if objects.size() != HEIGHT:
		problems.append("%s: object grid has %d rows, expected %d"
			% [label, objects.size(), HEIGHT])
		ok = false
	if not ok:
		return false
	for r in walls.size():
		var row: String = walls[r]
		if row.length() != WALL_W:
			problems.append("%s: wall row %d is %d wide, expected %d"
				% [label, r, row.length(), WALL_W])
			ok = false
			continue
		for c in row.length():
			var want := ""
			if r % 2 == 0 and c % 2 == 0:
				want = "+"
			elif r % 2 == 0:
				want = "-."
			elif c % 2 == 0:
				want = "|."
			else:
				want = "."
			if not want.contains(row[c]):
				problems.append("%s: wall (%d, %d) is '%s', expected one of '%s'"
					% [label, c, r, row[c], want])
				ok = false
	for y in objects.size():
		var row: String = objects[y]
		if row.length() != WIDTH:
			problems.append("%s: object row %d is %d wide, expected %d"
				% [label, y, row.length(), WIDTH])
			ok = false
			continue
		for x in row.length():
			if not OBJECTS.has(row[x]):
				problems.append("%s: object row %d: unknown symbol '%s'" % [label, y, row[x]])
				ok = false
	return ok


static func _is_course_row(row: int) -> bool:
	for course_row in COURSE_ROWS:
		if row == course_row or row == course_row + 1:
			return true
	return false


static func _row_has_lane(objects: Array, row: int) -> bool:
	for x in WIDTH:
		if is_lane(glyph_at(objects, x, row)):
			return true
	return false


static func _lane_cells(objects: Array) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for y in objects.size():
		var row: String = objects[y]
		for x in row.length():
			if is_lane(row[x]):
				cells.append(Vector2i(x, y))
	return cells


static func _scratch(room: Dictionary) -> TowerData:
	var tower := TowerData.new(Tuning.COLS, HEIGHT)
	for y in HEIGHT:
		for x in WIDTH:
			apply_cell(tower, Vector2i(x, y), room["walls"], room["objects"], x, y)
	return tower


static func _lane_framed(tower: TowerData, pos: Vector2i) -> bool:
	return tower.barred_edge(pos, pos + Vector2i(-1, 0))


static func _validate_route(room: Dictionary, band: int, label: String,
		problems: PackedStringArray) -> void:
	var walls: Array = room["walls"]
	var objects: Array = room["objects"]
	var entry := Vector2i(0, 0)
	var exit := Vector2i(WIDTH - 1, HEIGHT - 1)
	if not is_lane(glyph_at(objects, entry.x, entry.y)):
		problems.append("%s has no lane at its entry port (0, 0)" % label)
		return
	if not is_lane(glyph_at(objects, exit.x, exit.y)):
		problems.append("%s has no lane at its exit port (%d, %d)" % [label, exit.x, exit.y])
		return

	var tower := _scratch(room)
	var lane := _lane_cells(objects)

	if tower.at(entry).bars & Cell.BAR_TOP != 0:
		problems.append("%s: the entry port is roofed, so the seam step in is barred" % label)
	if tower.at(exit).bars & (Cell.BAR_BOTTOM | Cell.BAR_RIGHT) != 0:
		problems.append("%s: the exit port is walled on its outer side or its foot" % label)

	for pos in lane:
		if tower.at(pos).kind == Cell.Kind.WINDOW:
			problems.append("%s: lane cell (%d, %d) is a window" % [label, pos.x, pos.y])

	var reached: Dictionary = {entry: true}
	var queue: Array[Vector2i] = [entry]
	var head := 0
	while head < queue.size():
		var at := queue[head]
		head += 1
		for dir in TowerData.DIRS:
			var next := at + dir
			if next.x < 0 or next.x >= WIDTH or next.y < 0 or next.y >= HEIGHT:
				continue
			if reached.has(next) or not is_lane(glyph_at(objects, next.x, next.y)):
				continue
			if not tower.can_player_enter(at, next):
				continue
			reached[next] = true
			queue.append(next)

	if not reached.has(exit):
		problems.append("%s: the lane does not reach its exit port" % label)
	for pos in lane:
		if not reached.has(pos):
			problems.append("%s: lane cell (%d, %d) is cut off from the entry port"
				% [label, pos.x, pos.y])

	var by_row: Dictionary = {}
	for pos in lane:
		var xs: Array = by_row.get(pos.y, [])
		xs.append(pos.x)
		by_row[pos.y] = xs
	var framed_near_entry := false
	for y: int in by_row:
		var xs: Array = by_row[y]
		if xs.size() != 1 or _is_course_row(y):
			continue
		var pos := Vector2i(xs[0], y)
		if pos.x == 0:
			continue
		if not _lane_framed(tower, pos):
			problems.append("%s: the lane descends unwalled at (%d, %d)" % [label, pos.x, pos.y])
		elif y <= ROUTE_ENTRY_FRAME_ROWS:
			framed_near_entry = true

	if not framed_near_entry:
		problems.append("%s: the lane is unwalled for its first %d rows"
			% [label, ROUTE_ENTRY_FRAME_ROWS + 1])

	for course_row in COURSE_ROWS:
		for row in [course_row, course_row + 1]:
			var gaps: Array[int] = []
			for x in WIDTH:
				if bars_at(walls, x, row) & Cell.BAR_TOP == 0:
					gaps.append(x)
			if gaps.size() != 1:
				problems.append("%s: course row %d has %d gaps, wanted exactly one"
					% [label, row, gaps.size()])
			elif not _row_has_lane(objects, row):
				problems.append("%s: the lane never reaches course row %d" % [label, row])

	if band == Band.LOWER:
		var lids := 0
		for y in HEIGHT:
			for x in WIDTH:
				if bars_at(walls, x, y) != Cell.BAR_TOP:
					continue
				for pos in lane:
					if absi(pos.x - x) <= 1 and absi(pos.y - y) <= 1:
						lids += 1
						break
		if lids < ROUTE_LOWER_MIN_LIDS:
			problems.append("%s: only %d lids within a step of the lane, wanted %d"
				% [label, lids, ROUTE_LOWER_MIN_LIDS])


static func _validate_wall(room: Dictionary, label: String,
		problems: PackedStringArray) -> void:
	var walls: Array = room["walls"]
	for x in WIDTH:
		for y in HEIGHT:
			if is_lane(glyph_at(room["objects"], x, y)):
				problems.append("%s: a lane glyph in a wall template" % label)
				return

	var left := bars_at(walls, 0, HEIGHT - 1)
	if left & (Cell.BAR_LEFT | Cell.BAR_BOTTOM) != 0:
		problems.append("%s: bottom-left stone walls the seam step" % label)
	var right := bars_at(walls, WIDTH - 1, HEIGHT - 1)
	if right & (Cell.BAR_RIGHT | Cell.BAR_BOTTOM) != 0:
		problems.append("%s: bottom-right stone walls the seam step when mirrored" % label)

	for course_row in COURSE_ROWS:
		for row in [course_row, course_row + 1]:
			for x in WIDTH:
				if bars_at(walls, x, row) & Cell.BAR_TOP == 0:
					problems.append("%s: course row %d is open at column %d"
						% [label, row, x])

	var shoulder := 0
	for y in 4:
		for x in range(2, WIDTH):
			if bars_at(walls, x, y) != 0:
				shoulder += 1
	if shoulder < WALL_MIN_SHOULDER:
		problems.append("%s: %d casters in its upwind shoulder, wanted %d"
			% [label, shoulder, WALL_MIN_SHOULDER])


static func _validate_windows(objects: Array, label: String,
		problems: PackedStringArray) -> void:
	for symbol: String in WINDOW_GLYPHS:
		var size: Vector2i = WINDOW_GLYPHS[symbol]
		var count := 0
		var blocks := 0
		for y in objects.size():
			var row: String = objects[y]
			for x in row.length():
				if row[x] != symbol:
					continue
				count += 1
				if not is_window_origin(objects, x, y):
					continue
				blocks += 1
				if x + size.x > WIDTH or y + size.y > HEIGHT:
					problems.append("%s: %s window at (%d,%d) runs off the room"
						% [label, symbol, x, y])
					continue
				for dy in size.y:
					for dx in size.x:
						if glyph_at(objects, x + dx, y + dy) != symbol:
							problems.append(
								"%s: %s window at (%d,%d) is not a full %dx%d block"
								% [label, symbol, x, y, size.x, size.y])
		if count != blocks * size.x * size.y:
			problems.append("%s: %d %s cells do not tile into whole windows"
				% [label, count, symbol])


static func caster_stats() -> Dictionary:
	var per_room: Dictionary = {}
	var edges: Dictionary = {}
	var windows := 0.0
	var casters := 0.0
	for band in [Band.UPPER, Band.MIDDLE, Band.LOWER]:
		for entry in [[route_pool_for(band), 1.0], [wall_pool_for(band), float(Tuning.FACES - 1)]]:
			var pool: Array = entry[0]
			var faces: float = entry[1]
			var share: float = faces / float(maxi(1, pool.size()))
			for room: Dictionary in pool:
				var walls: Array = room["walls"]
				var objects: Array = room["objects"]
				for y in HEIGHT:
					for x in WIDTH:
						var bars := bars_at(walls, x, y)
						if bars != 0:
							casters += share
							edges[bars] = edges.get(bars, 0.0) + share
						var spec: Dictionary = OBJECTS.get(glyph_at(objects, x, y), OBJECTS["."])
						if spec["kind"] == Cell.Kind.WINDOW:
							windows += share
	var rooms := float(Tuning.FACES * 3)
	per_room["rooms"] = rooms
	per_room["casters_per_room"] = casters / rooms
	per_room["windows_per_room"] = windows / rooms
	per_room["edges"] = edges
	per_room["lane_framed"] = lane_frame_stats()
	return per_room


static func lane_frame_stats() -> Dictionary:
	var out: Dictionary = {}
	for band in [Band.UPPER, Band.MIDDLE, Band.LOWER]:
		var lane := 0
		var framed := 0
		for room: Dictionary in route_pool_for(band):
			var tower := _scratch(room)
			for pos in _lane_cells(room["objects"]):
				lane += 1
				if _lane_framed(tower, pos):
					framed += 1
		out[band] = 0.0 if lane == 0 else float(framed) / float(lane)
	return out
