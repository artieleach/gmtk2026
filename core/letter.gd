class_name Letter extends RefCounted


var pos: Vector2i
var sent: bool = false


static func create(p_pos: Vector2i) -> Letter:
	var letter := Letter.new()
	letter.pos = p_pos
	return letter


func turns() -> int:
	return Tuning.LETTER_TURNS


const EXCUSES: Array[String] = [
	"[excuse 1]",
	"[excuse 2]",
	"[excuse 3]",
	"[excuse 4]",
	"[excuse 5]",
	"[excuse 6]",
	"[excuse 7]",
	"[excuse 8]",
]


static func excuse(index: int) -> String:
	if EXCUSES.is_empty():
		return ""
	return EXCUSES[clampi(index, 0, EXCUSES.size() - 1)]
