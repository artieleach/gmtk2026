class_name SunModel extends RefCounted


var dawn_turns: int = Tuning.DAWN_TURNS
var fill_turns: int = Tuning.SHADE_FILL_TURNS
var fill_easing: float = Tuning.SHADE_FILL_EASING
var elev_start_deg: float = Tuning.SUN_ELEV_START_DEG
var elev_end_deg: float = Tuning.SUN_ELEV_END_DEG
var rise_easing: float = Tuning.SUN_RISE_EASING
var rake_deg: float = Tuning.SUN_RAKE_DEG
var reach: float = Tuning.BARRIER_REACH
var front_at_sunrise: float = Tuning.FRONT_ROW_AT_SUNRISE
var horizon_distance: float = Tuning.HORIZON_DISTANCE_TILES


func progress(turn: float) -> float:
	if dawn_turns <= 0:
		return 1.0
	return clampf(float(turn) / float(dawn_turns), 0.0, 1.0)


func elevation_deg(turn: float) -> float:
	return lerpf(elev_start_deg, elev_end_deg, pow(progress(turn), rise_easing))


func fill_start_turn() -> int:
	return dawn_turns - fill_turns


func shade_fill(turn: float) -> float:
	if fill_turns <= 0:
		return 1.0 if progress(turn) >= 1.0 else 0.0
	var elapsed := float(turn) - float(fill_start_turn())
	return pow(clampf(elapsed / float(fill_turns), 0.0, 1.0), fill_easing)


func shadow_offset(turn: float) -> Vector2:
	var open := 1.0 - shade_fill(turn)
	var rake := deg_to_rad(rake_deg * open)
	var elevation := deg_to_rad(elevation_deg(turn))
	return Vector2(tan(rake), tan(elevation) / cos(rake)) * (reach * open)


func shadow_angle_deg(turn: float) -> float:
	var offset := shadow_offset(turn)
	if offset == Vector2.ZERO:
		return -90.0
	return -rad_to_deg(atan2(offset.y, offset.x))


func shadow_length(turn: float) -> float:
	return shadow_offset(turn).length()


func front_row(turn: float) -> float:
	return front_at_sunrise + horizon_distance * tan(deg_to_rad(elevation_deg(turn)))


func is_row_lit(row: int, turn: int) -> bool:
	return float(row) < front_row(turn)


func casts_shadows(turn: float) -> bool:
	return shade_fill(turn) < 1.0


func turns_until_daybreak(turn: int) -> int:
	return maxi(0, dawn_turns - turn)
