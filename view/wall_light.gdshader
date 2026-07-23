shader_type canvas_item;


const int MAX_SHADOW_CELLS = 48;
const int MAX_LANTERN_CELLS = 12;
const int MAX_LANTERNS = 4;

const float NEVER = 1e18;
const float MIN_REACH = 0.0001;

uniform vec2 wall_min;
uniform vec2 wall_max;
uniform vec2 grid_size;

uniform sampler2D depth_tex : filter_nearest, repeat_enable;
uniform float depth_scale = 255.0;

uniform float front_row;
uniform vec2 offset_per_depth;
uniform float max_depth;
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


float depth_at(ivec2 cell) {
	return texture(depth_tex, (vec2(cell) + vec2(0.5)) / grid_size).r * depth_scale;
}


ivec2 cell_of(vec2 wall) {
	return ivec2(floor(wall + vec2(0.5)));
}


float shadow_margin(vec2 wall) {
	float floor_margin = -max_depth - 1.0;
	if (!casts_shadows || max_depth <= 0.0 || length(offset_per_depth) < MIN_REACH) {
		return floor_margin;
	}

	ivec2 cell = cell_of(wall);
	float here = depth_at(cell);
	if (here > 0.0) {
		return here;
	}

	vec2 dir = -offset_per_depth;
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
		if (next.x < next.y) {
			enter = next.x;
			cell.x += stp.x;
			next.x += span.x;
		} else {
			enter = next.y;
			cell.y += stp.y;
			next.y += span.y;
		}
		if (cell.y < 0 || cell.y >= int(grid_size.y)) {
			break;
		}
		float depth = depth_at(cell);
		if (depth > 0.0) {
			margin = max(margin, depth - enter);
			if (margin >= 0.0) {
				break;
			}
		}
		if (enter > max_depth) {
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


bool lantern_blocked(vec2 wall, vec2 delta, float source_depth) {
	ivec2 cell = cell_of(wall);
	if (depth_at(cell) > 0.0) {
		return true;
	}

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
		if (next.x < next.y) {
			enter = next.x;
			cell.x += stp.x;
			next.x += span.x;
		} else {
			enter = next.y;
			cell.y += stp.y;
			next.y += span.y;
		}
		if (enter > 1.0) {
			return false;
		}
		if (cell.y < 0 || cell.y >= int(grid_size.y)) {
			return true;
		}
		if (depth_at(cell) > source_depth * enter) {
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
		if (!lantern_blocked(wall, delta, lamp.z)) {
			return true;
		}
	}
	return false;
}


void fragment() {
	vec2 wall = mix(wall_min, wall_max, UV);

	vec4 result = vec4(0.0);
	if (wall.y >= -0.5 && wall.y < grid_size.y - 0.5) {
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
	COLOR = result;
}
