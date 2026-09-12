shader_type spatial;

// CULLING OPTIONS
// Options: cull_back (default), cull_front, cull_disabled (two-sided)
render_mode cull_back;

// TRANSPARENCY & LIGHTING
// Options: depth_draw_always ensures correct depth testing for transparent materials
render_mode blend_mix, depth_draw_always, diffuse_lambert, specular_schlick_ggx;

group_uniforms Base_Color;
uniform vec4 albedo : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform sampler2D albedo_texture : hint_default_white, source_color;

group_uniforms Per_Face_Variation;
uniform float hue_variance : hint_range(0.0, 0.5) = 0.00;
uniform float sat_variance : hint_range(0.0, 0.5) = 0.1;
uniform float val_variance : hint_range(0.0, 0.5) = 0.05;

group_uniforms Surface_PBR;
uniform float metallic : hint_range(0.0, 1.0) = 0.0;
uniform float roughness : hint_range(0.0, 1.0) = 1.0;

group_uniforms Rim_Light;
uniform float rim_strength : hint_range(0.0, 3.0) = 0.4;
uniform float rim_power : hint_range(0.5, 8.0) = 3.0;
uniform vec4 rim_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

group_uniforms Refraction;
uniform float refraction_strength : hint_range(0.0, 1.0) = 0.05;
uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;

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

void vertex() {
	v_flat_seed = vec3(float(VERTEX_ID));
}

void fragment() {
	// 1. Base Albedo
	vec4 tex_color = texture(albedo_texture, UV);
	vec3 base_color = (tex_color * albedo).rgb;
	float base_alpha = tex_color.a * albedo.a;

	// 2. Per-Face Color Variation
	float rand_h = hash3(v_flat_seed + vec3(0.1, 0.2, 0.3)) * 2.0 - 1.0;
	float rand_s = hash3(v_flat_seed + vec3(0.4, 0.5, 0.6)) * 2.0 - 1.0;
	float rand_v = hash3(v_flat_seed + vec3(0.7, 0.8, 0.9)) * 2.0 - 1.0;

	vec3 hsv = rgb2hsv(base_color);
	hsv.x = fract(hsv.x + (rand_h * hue_variance));
	hsv.y = clamp(hsv.y + (rand_s * sat_variance), 0.0, 1.0);
	hsv.z = clamp(hsv.z + (rand_v * val_variance), 0.0, 1.0);

	vec3 final_albedo = hsv2rgb(hsv);

	// 3. Flat shading (optional flat normal calculation for low-poly look)
	vec3 x_deriv = dFdx(VERTEX);
	vec3 y_deriv = dFdy(VERTEX);
	NORMAL = normalize(cross(y_deriv, x_deriv));

	// 4. Refraction Calculation
	// Distorts the screen texture UV based on view-space normals and refraction strength
	vec2 ref_offset = NORMAL.xy * refraction_strength * 0.1;
	vec3 ref_color = texture(screen_texture, SCREEN_UV + ref_offset).rgb;

	// Blend albedo with refracted background based on alpha
	ALBEDO = mix(ref_color, final_albedo, base_alpha);
	ALPHA = base_alpha;

	// 5. Rim Light (fresnel highlight on silhouette edges, for a stylized low-poly look)
	float rim_fresnel = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), rim_power);
	EMISSION += rim_color.rgb * rim_fresnel * rim_strength;

	// 6. Material PBR Outputs
	METALLIC = metallic;
	ROUGHNESS = roughness;
}
