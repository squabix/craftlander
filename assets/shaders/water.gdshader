shader_type spatial;
// Changed render_mode to depth_draw_always so transparency draws correctly
render_mode specular_schlick_ggx, cull_back, depth_draw_always;

uniform sampler2D noise_tex_1;
uniform sampler2D noise_tex_2;

uniform vec3 deep_color : source_color = vec3(0.0, 0.15, 0.25);
uniform vec3 shallow_color : source_color = vec3(0.05, 0.35, 0.45);

uniform float wave_speed = 0.05;
uniform float wave_scale = 4.0;
uniform float wave_height = 0.3;

uniform float roughness = 0.15;
uniform float metallic = 0.0;

// --- NEW UNIFORMS FOR THE CENTER FADE ---
uniform float fade_radius = 20.0;   // Distance from center where fading starts
uniform float fade_max = 25.0;      // Distance where water becomes fully invisible

varying flat float v_flat_wave_height;
varying vec3 v_world_pos;           // Removed 'flat' for smooth interpolation

void vertex() {
	vec2 world_uv = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz * wave_scale;

	vec2 scroll1 = world_uv + TIME * wave_speed;
	vec2 scroll2 = world_uv - TIME * wave_speed * 0.7;

	float n1 = texture(noise_tex_1, scroll1).r;
	float n2 = texture(noise_tex_2, scroll2).r;

	float wave = (n1 + n2) * 0.5;

	VERTEX.y += wave * wave_height;
	
	v_flat_wave_height = wave;
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float height_mask = smoothstep(0.2, 0.8, v_flat_wave_height); 
	vec3 water_color = mix(deep_color, shallow_color, height_mask);

	vec3 x_deriv = dFdx(VERTEX);
	vec3 y_deriv = dFdy(VERTEX);
	vec3 flat_normal = normalize(cross(y_deriv, x_deriv));
	NORMAL = flat_normal;

	ALBEDO = water_color;
	ROUGHNESS = roughness;
	METALLIC = metallic;

	// --- NEW CENTER FADE LOGIC ---
	// NODE_POSITION_WORLD is the absolute center of this water mesh in the world
	float dist = distance(v_world_pos.xz, NODE_POSITION_WORLD.xz);
	
	// Fade out towards the edges based on the distance from the center
	float fade = smoothstep(fade_radius, fade_max, dist);
	
	ALPHA = 1.0 - fade;
}