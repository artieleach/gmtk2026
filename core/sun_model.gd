class_name SunModel extends RefCounted


var dawn_turns: int = Tuning.DAWN_TURNS
var fill_turns: int = Tuning.SHADE_FILL_TURNS
var stand_share: float = Tuning.SHADE_STAND_SHARE
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


func shrink_start_turn() -> int:
	return dawn_turns - roundi(float(fill_turns) * (1.0 - stand_share))


func _fill_raw(turn: float) -> float:
	if fill_turns <= 0:
		return 1.0 if progress(turn) >= 1.0 else 0.0
	return clampf((float(turn) - float(fill_start_turn())) / float(fill_turns), 0.0, 1.0)


func stand_fill(turn: float) -> float:
	if stand_share <= 0.0:
		return 1.0
	return clampf(_fill_raw(turn) / stand_share, 0.0, 1.0)


func shade_fill(turn: float) -> float:
	if stand_share >= 1.0:
		return 1.0 if _fill_raw(turn) >= 1.0 else 0.0
	var retreat := (_fill_raw(turn) - stand_share) / (1.0 - stand_share)
	return pow(clampf(retreat, 0.0, 1.0), fill_easing)


func shadow_offset(turn: float) -> Vector2:
	var elevation := deg_to_rad(elevation_deg(turn))
	var open_rake := deg_to_rad(rake_deg)
	var full := Vector2(tan(open_rake), tan(elevation) / cos(open_rake))
	var rake := deg_to_rad(rake_deg * (1.0 - stand_fill(turn)))
	var direction := Vector2(tan(rake), tan(elevation) / cos(rake))
	if direction == Vector2.ZERO:
		return Vector2.ZERO
	return direction.normalized() * (full.length() * reach * (1.0 - shade_fill(turn)))


func shadow_length(turn: float) -> float:
	return shadow_offset(turn).length()


func shadow_angle_deg(turn: float) -> float:
	var offset := shadow_offset(turn)
	if offset == Vector2.ZERO:
		return -90.0
	return -rad_to_deg(atan2(offset.y, offset.x))


func front_row(turn: float) -> float:
	return front_at_sunrise + horizon_distance * tan(deg_to_rad(elevation_deg(turn)))


func casts_shadows(turn: float) -> bool:
	return shade_fill(turn) < 1.0


func turns_until_daybreak(turn: int) -> int:
	return maxi(0, dawn_turns - turn)
