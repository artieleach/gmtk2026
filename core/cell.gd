class_name Cell extends RefCounted


enum Kind {
	WALL,
	BRICK,
	LEDGE,
	PILASTER,
	WINDOW,
	RUBBLE,
	PEDESTAL,
}

const BAR_TOP := 1
const BAR_RIGHT := 2
const BAR_BOTTOM := 4
const BAR_LEFT := 8

var blocked: bool = false
var kind: int = Kind.WALL
var bars: int = 0
var route: bool = false


func casts_shadow() -> bool:
	return bars != 0


func bars_side(flag: int) -> bool:
	return bars & flag != 0


static func bar_for(dir: Vector2i) -> int:
	if dir == Vector2i(0, -1):
		return BAR_TOP
	if dir == Vector2i(0, 1):
		return BAR_BOTTOM
	if dir == Vector2i(-1, 0):
		return BAR_LEFT
	if dir == Vector2i(1, 0):
		return BAR_RIGHT
	return 0


static func dir_for(flag: int) -> Vector2i:
	match flag:
		BAR_TOP:
			return Vector2i(0, -1)
		BAR_BOTTOM:
			return Vector2i(0, 1)
		BAR_LEFT:
			return Vector2i(-1, 0)
		BAR_RIGHT:
			return Vector2i(1, 0)
	return Vector2i.ZERO


static func opposite(flag: int) -> int:
	match flag:
		BAR_TOP:
			return BAR_BOTTOM
		BAR_BOTTOM:
			return BAR_TOP
		BAR_LEFT:
			return BAR_RIGHT
		BAR_RIGHT:
			return BAR_LEFT
	return 0
