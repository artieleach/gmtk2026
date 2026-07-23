class_name Cell extends RefCounted


enum Kind {
	WALL,
	BRICK,
	LEDGE,
	CORNICE,
	WINDOW,
	RUBBLE,
	ALTAR,
}

var blocked: bool = false
var protrusion_depth: int = 0
var kind: int = Kind.WALL


func casts_shadow() -> bool:
	return protrusion_depth > 0
