//https://godotshaders.com/shader/3d-tree-sway-wind-shader-v0-5/

shader_type spatial;
render_mode cull_disabled;

uniform bool debug_mode = false;

uniform float wind_direction = 90.0f;
uniform float wind_strenth = 3.0f;
uniform float sway_speed = 3.0f;
uniform float bendieness_multiplier = 0.0f;

uniform sampler2D albedo_texture : source_color;

group_uniforms Per_Face_Variation;
uniform float hue_variance : hint_range(0.0, 0.5) = 0.00;
uniform float sat_variance : hint_range(0.0, 0.5) = 0.05;
uniform float val_variance : hint_range(0.0, 0.5) = 0.05;

varying float wind_multiplier;

// Flat varying ensures the same per-face seed is shared across the entire triangle face.
// Seeded from VERTEX_ID (the vertex buffer index) rather than world position, since it stays
// constant even though vertex() below displaces VERTEX for wind sway.
varying flat vec3 v_flat_seed;

// Pseudo-random generator from a 3D position vector
float hash3(vec3 p) {
	p = fract(p * vec3(443.8975, 397.2973, 491.1871));
	p += dot(p.xyz, p.yzx + 19.19);
	return fract(p.x * p.y * p.z);
}

// Color conversion helpers
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

// convert degrees to a vec2 direction.
vec2 rotation_to_direction()
{
	float rotation_radians = wind_direction * (3.14f / 180.0f);
	vec2 direction = vec2(cos(rotation_radians), sin(rotation_radians));
	
	return normalize(direction);
}

void vertex() {
	v_flat_seed = vec3(float(VERTEX_ID));

	// distance to the worlds.y 0.
    vec3 world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    float dist = world_pos.y;
	
	// DEBUG: applies visual gradients.
    if (debug_mode)
	{
		float gradient = clamp(dist * 0.2, 0.0, 1.0);
    	COLOR = vec4(gradient, gradient, gradient, 1.0);
	}
	
	// magic 100.0f just to make it easier to adjust in property panel
	float sway = sin(TIME * sway_speed + VERTEX.y) * wind_strenth / 100.0f;
    VERTEX.x += (sway * dist);
	
	// magic 100.0f just to make it easier to adjust in property panel
	vec2 wind_bending = vec2((wind_strenth / 100.0f) * dist) * rotation_to_direction();
	VERTEX.xz += wind_bending * bendieness_multiplier;
}

void fragment() {
    vec3 tex_color = texture(albedo_texture, UV).rgb;

	// Per-Face Color Variation
	float rand_h = hash3(v_flat_seed + vec3(0.1, 0.2, 0.3)) * 2.0 - 1.0;
	float rand_s = hash3(v_flat_seed + vec3(0.4, 0.5, 0.6)) * 2.0 - 1.0;
	float rand_v = hash3(v_flat_seed + vec3(0.7, 0.8, 0.9)) * 2.0 - 1.0;

	vec3 hsv = rgb2hsv(tex_color);
	hsv.x = fract(hsv.x + (rand_h * hue_variance));
	hsv.y = clamp(hsv.y + (rand_s * sat_variance), 0.0, 1.0);
	hsv.z = clamp(hsv.z + (rand_v * val_variance), 0.0, 1.0);
	vec3 varied_color = hsv2rgb(hsv);

    if (debug_mode) {
        ALBEDO = COLOR.rgb;
    } else {
        ALBEDO = varied_color;
    }
}