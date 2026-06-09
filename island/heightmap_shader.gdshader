shader_type spatial;
render_mode diffuse_lambert, specular_schlick_ggx;

uniform sampler2D heightmap;
uniform sampler2D gradient;
uniform float max_height;
uniform float zero_displacement;
uniform float roughness = 1.0;

uniform float hue_variance : hint_range(0.0, 0.1) = 0.03;
uniform float sat_variance : hint_range(0.0, 0.2) = 0.05;
uniform float val_variance : hint_range(0.0, 0.2) = 0.05;

varying flat float v_height;
varying flat vec3 v_flat_world_pos; 
uniform float grid_distortion : hint_range(0.0, 0.5) = 0.15;

// Generate a offset vector based on grid position
vec2 hash22(vec2 p) {
	p = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)));
	return fract(sin(p) * 43758.5453123) - 0.5;
}

void vertex() {
	vec2 grid_pos = VERTEX.xz;
	vec2 offset = hash22(grid_pos) * grid_distortion;
	
	VERTEX.x += offset.x;
	VERTEX.z += offset.y;
	
	vec2 distorted_uv = UV + (offset / max_height);

	float h = texture(heightmap, distorted_uv).r;
	v_height = clamp(h, 0.0, 1.0);
	VERTEX.y += h * max_height;
	
	if (h == 0.0) {
		VERTEX.y += zero_displacement;
	}
	
	v_flat_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

float hash3(vec3 p) {
	p = fract(p * vec3(443.8975, 397.2973, 491.1871));
	p += dot(p.xyz, p.yzx + 19.19);
	return fract(p.x * p.y * p.z);
}

vec3 rgb2hsv(vec3 c) {
	vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
	vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
	vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

	float d = q.x - min(q.w, q.y);
	float e = 1.0e-10;
	return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsv2rgb(vec3 c) {
	vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
	vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
	return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

void fragment() {
	vec3 grad_color = texture(gradient, vec2(1.0 - v_height, 0.5)).rgb;

	vec3 x_deriv = dFdx(VERTEX);
	vec3 y_deriv = dFdy(VERTEX);
	vec3 flat_normal = normalize(cross(y_deriv, x_deriv));
	NORMAL = flat_normal;
	
	float rand_h = hash3(v_flat_world_pos + vec3(0.1, 0.2, 0.3)) * 2.0 - 1.0;
	float rand_s = hash3(v_flat_world_pos + vec3(0.4, 0.5, 0.6)) * 2.0 - 1.0;
	float rand_v = hash3(v_flat_world_pos + vec3(0.7, 0.8, 0.9)) * 2.0 - 1.0;

	vec3 hsv = rgb2hsv(grad_color);
	hsv.x = fract(hsv.x + (rand_h * hue_variance));
	hsv.y = clamp(hsv.y + (rand_s * sat_variance), 0.0, 1.0);
	hsv.z = clamp(hsv.z + (rand_v * val_variance), 0.0, 1.0);

	ALBEDO = hsv2rgb(hsv);
	ROUGHNESS = roughness;
}