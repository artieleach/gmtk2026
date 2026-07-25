const int MAX_SHADOW_CELLS = 48;
const int MAX_LANTERN_CELLS = 12;
const int MAX_LANTERNS = 4;

const float NEVER = 1e18;
const float MIN_REACH = 0.0001;

uniform vec2 wall_min;
uniform vec2 wall_max;
uniform vec2 grid_size;

uniform float top_row = -0.5;

uniform sampler2D bars_tex : filter_nearest, repeat_enable;

const int BAR_TOP = 1;
const int BAR_RIGHT = 2;
const int BAR_BOTTOM = 4;
const int BAR_LEFT = 8;

uniform float front_row;
uniform vec2 shadow_offset;
uniform bool casts_shadows;

uniform int lantern_count = 0;
uniform vec4 lanterns[MAX_LANTERNS];

uniform vec4 lit_color : source_color;
uniform vec4 lantern_color : source_color;
uniform vec4 shaded_color : source_color;
uniform vec4 dark_color : source_color;
uniform vec4 front_line_color : source_color;
uniform float front_line_width = 0.035;
uniform float face_shade = 1.0;
uniform float lantern_height = 0.6;


int bars_at(ivec2 cell) {
	if (cell.y < 0 || cell.y >= int(grid_size.y)) {
		return 0;
	}
	return int(texture(bars_tex, (vec2(cell) + vec2(0.5)) / grid_size).r * 255.0 + 0.5);
}


ivec2 cell_of(vec2 wall) {
	return ivec2(floor(wall + vec2(0.5)));
}


int bar_for(ivec2 step) {
	if (step.y < 0) { return BAR_TOP; }
	if (step.y > 0) { return BAR_BOTTOM; }
	return step.x < 0 ? BAR_LEFT : BAR_RIGHT;
}


bool barred_edge(ivec2 from_cell, ivec2 into) {
	int flag = bar_for(into - from_cell);
	int back = flag == BAR_TOP ? BAR_BOTTOM
		: flag == BAR_BOTTOM ? BAR_TOP
		: flag == BAR_LEFT ? BAR_RIGHT : BAR_LEFT;
	return (bars_at(from_cell) & flag) != 0 || (bars_at(into) & back) != 0;
}


float shadow_margin(vec2 wall) {
	float floor_margin = -2.0;
	if (!casts_shadows || length(shadow_offset) < MIN_REACH) {
		return floor_margin;
	}

	ivec2 cell = cell_of(wall);
	vec2 dir = -shadow_offset;
	ivec2 stp = ivec2(dir.x > 0.0 ? 1 : -1, dir.y > 0.0 ? 1 : -1);
	vec2 next = vec2(NEVER);
	vec2 span = vec2(NEVER);
	if (abs(dir.x) > 0.0) {
		next.x = (float(cell.x) + 0.5 * float(stp.x) - wall.x) / dir.x;
		span.x = 1.0 / abs(dir.x);
	}
	if (abs(dir.y) > 0.0) {
		next.y = (float(cell.y) + 0.5 * float(stp.y) - wall.y) / dir.y;
		span.y = 1.0 / abs(dir.y);
	}

	float margin = floor_margin;
	for (int i = 0; i < MAX_SHADOW_CELLS; i++) {
		float enter;
		ivec2 into = cell;
		if (next.x < next.y) {
			enter = next.x;
			into.x += stp.x;
			next.x += span.x;
		} else {
			enter = next.y;
			into.y += stp.y;
			next.y += span.y;
		}
		if (barred_edge(cell, into)) {
			margin = max(margin, 1.0 - enter);
			if (margin >= 0.0) {
				break;
			}
		}
		if (enter > 1.0) {
			break;
		}
		cell = into;
		if (cell.y < 0 || cell.y >= int(grid_size.y)) {
			break;
		}
	}
	return margin;
}


vec2 wall_delta(vec2 from, vec2 to) {
	float dx = from.x - to.x;
	dx -= grid_size.x * floor(dx / grid_size.x + 0.5);
	return vec2(dx, from.y - to.y);
}


bool lantern_blocked(vec2 wall, vec2 delta) {
	ivec2 cell = cell_of(wall);
	vec2 dir = -delta;
	ivec2 stp = ivec2(dir.x > 0.0 ? 1 : -1, dir.y > 0.0 ? 1 : -1);
	vec2 next = vec2(NEVER);
	vec2 span = vec2(NEVER);
	if (abs(dir.x) > 0.0) {
		next.x = (float(cell.x) + 0.5 * float(stp.x) - wall.x) / dir.x;
		span.x = 1.0 / abs(dir.x);
	}
	if (abs(dir.y) > 0.0) {
		next.y = (float(cell.y) + 0.5 * float(stp.y) - wall.y) / dir.y;
		span.y = 1.0 / abs(dir.y);
	}

	for (int i = 0; i < MAX_LANTERN_CELLS; i++) {
		float enter;
		ivec2 into = cell;
		if (next.x < next.y) {
			enter = next.x;
			into.x += stp.x;
			next.x += span.x;
		} else {
			enter = next.y;
			into.y += stp.y;
			next.y += span.y;
		}
		if (enter > 1.0) {
			return false;
		}
		if (barred_edge(cell, into) && lantern_height * enter < 1.0) {
			return true;
		}
		cell = into;
		if (cell.y < 0 || cell.y >= int(grid_size.y)) {
			return true;
		}
	}
	return false;
}


bool lantern_lights(vec2 wall) {
	for (int i = 0; i < MAX_LANTERNS; i++) {
		if (i >= lantern_count) {
			break;
		}
		vec4 lamp = lanterns[i];
		vec2 delta = wall_delta(wall, lamp.xy);
		if (length(delta) > lamp.w) {
			continue;
		}
		if (!lantern_blocked(wall, delta)) {
			return true;
		}
	}
	return false;
}


vec4 light_at(vec2 wall) {
	vec4 result = vec4(0.0);
	if (wall.y >= top_row && wall.y < grid_size.y - 0.5) {
		bool below_front = wall.y >= front_row;
		bool shaded = shadow_margin(wall) >= 0.0;
		result = below_front ? dark_color : (shaded ? shaded_color : lit_color);

		if ((below_front || shaded) && lantern_lights(wall)) {
			result = lantern_color;
		}

		float edge = abs(wall.y - front_row);
		if (edge < front_line_width) {
			result = mix(result, front_line_color,
				front_line_color.a * (1.0 - edge / front_line_width));
		}

		result.rgb *= face_shade;
	}
	return result;
}
