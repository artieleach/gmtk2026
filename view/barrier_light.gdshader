shader_type canvas_item;


#include "res://view/wall_light.gdshaderinc"

uniform vec2 screen_x_span;


void fragment() {
	float u = (SCREEN_UV.x - screen_x_span.x) / (screen_x_span.y - screen_x_span.x);
	vec4 light = light_at(mix(wall_min, wall_max, vec2(u, SCREEN_UV.y)));
	COLOR.rgb = mix(COLOR.rgb, light.rgb, light.a);
}
