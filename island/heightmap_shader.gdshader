shader_type spatial;

uniform sampler2D heightmap;
uniform sampler2D gradient;
uniform sampler2D normal_map;
uniform float max_height;

varying float v_height;

void vertex() {
	float h = texture(heightmap, UV).r;
	v_height = clamp(h, 0.0, 1.0); // store for fragment
	VERTEX.y += h * max_height;
}

void fragment() {
	vec3 grad_color = texture(gradient, vec2(1.0 - v_height, 0.5)).rgb;

	ALBEDO = grad_color;
	NORMAL_MAP = texture(normal_map, UV).rgb;
}
