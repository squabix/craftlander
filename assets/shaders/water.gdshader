shader_type spatial;
render_mode specular_schlick_ggx, cull_back, depth_draw_opaque;

uniform sampler2D noise_tex_1;
uniform sampler2D noise_tex_2;

uniform vec3 deep_color : source_color = vec3(0.0, 0.15, 0.25);
uniform vec3 shallow_color : source_color = vec3(0.05, 0.35, 0.45);

uniform float wave_speed = 0.05;
uniform float wave_scale = 4.0;
uniform float normal_strength = 1.2;
uniform float wave_height = 0.3;

uniform float roughness = 0.15;
uniform float metallic = 0.0;

varying float wave_height_mask;

void vertex() {
	vec2 world_uv = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz * wave_scale;

	vec2 scroll1 = world_uv + TIME * wave_speed;
	vec2 scroll2 = world_uv - TIME * wave_speed * 0.7;

	float n1 = texture(noise_tex_1, scroll1).r;
	float n2 = texture(noise_tex_2, scroll2).r;

	float wave = (n1 + n2) * 0.5;

	VERTEX.y += wave * wave_height;
	wave_height_mask = wave;
}

void fragment() {
	// Base UVs
	vec2 uv = UV * wave_scale;

	// Scrolling noise
	vec2 scroll_1 = uv + vec2(TIME * wave_speed, TIME * wave_speed * 0.7);
	vec2 scroll_2 = uv - vec2(TIME * wave_speed * 0.6, TIME * wave_speed);

	float n1 = texture(noise_tex_1, scroll_1).r;
	float n2 = texture(noise_tex_2, scroll_2).r;

	// Combined wave noise
	float wave = (n1 + n2) * 0.5;

	// Fake vertical wave movement (visual illusion)
	float height_mask = smoothstep(0.2, 0.8, wave);
	vec3 water_color = mix(deep_color, shallow_color, height_mask);

	// Normal reconstruction from noise
	vec2 normal_uv_offset = vec2(
		texture(noise_tex_1, scroll_1 + vec2(0.01, 0.0)).r - n1,
		texture(noise_tex_2, scroll_2 + vec2(0.0, 0.01)).r - n2
	);

	vec3 normal = normalize(vec3(
		normal_uv_offset.x * normal_strength,
		1.0,
		normal_uv_offset.y * normal_strength
	));

	NORMAL = normal;

	ALBEDO = water_color;
	ROUGHNESS = roughness;
	METALLIC = metallic;
}
