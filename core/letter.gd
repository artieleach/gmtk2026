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
	"Detained on the upper floors. Begin without me.",
	"The stairs are not where I left them.",
	"A small matter of masonry. Very nearly resolved.",
	"There was a gargoyle. It started it.",
	"Held up by an errand both urgent and entirely genuine.",
	"My aunt. You remember my aunt.",
	"Cannot possibly explain in writing. Will explain in person.",
	"The sun and I are having a disagreement. Pour another.",
]


static func excuse(index: int) -> String:
	if EXCUSES.is_empty():
		return ""
	return EXCUSES[clampi(index, 0, EXCUSES.size() - 1)]
