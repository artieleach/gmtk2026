class_name HexProjection extends RefCounted


const FACES := 6
const FACE_ARC := TAU / FACES
const VISIBILITY_EPSILON := 0.001

var cols_per_face: int = Tuning.COLS_PER_FACE
var radius: float = Tuning.RADIUS
var yaw: float = 0.0


func apothem() -> float:
	return radius * sqrt(3.0) / 2.0


func face_angle(face: int) -> float:
	return float(face) * FACE_ARC + yaw


func face_facing(face: int) -> float:
	return cos(face_angle(face))


func is_face_visible(face: int) -> bool:
	return face_facing(face) > VISIBILITY_EPSILON


func column_width(face: int) -> float:
	return (radius / float(cols_per_face)) * absf(face_facing(face))


func face_of(col: int) -> int:
	return wrapi(col, 0, cols_per_face * FACES) / cols_per_face


func column_center_x(col: int) -> float:
	var wrapped := wrapi(col, 0, cols_per_face * FACES)
	var face := wrapped / cols_per_face
	var local := wrapped % cols_per_face
	var theta := face_angle(face)
	var u := (float(local) + 0.5) / float(cols_per_face) - 0.5
	return apothem() * sin(theta) + u * radius * cos(theta)


func protrusion_offset_x(face: int, depth: float) -> float:
	return depth * Tuning.TILE_W * sin(face_angle(face))


static func yaw_for_face(face: int) -> float:
	return -float(face) * FACE_ARC
