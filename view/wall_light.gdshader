shader_type canvas_item;


#include "res://view/wall_light.gdshaderinc"


void fragment() {
	COLOR = light_at(mix(wall_min, wall_max, UV));
}
