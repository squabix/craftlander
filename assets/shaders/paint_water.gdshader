shader_type spatial;
render_mode specular_schlick_ggx, cull_back, diffuse_lambert, depth_draw_always;

// Textures - For best results, use dedicated Normal Maps (RGB) instead of grayscale noise
uniform sampler2D normal_tex_1 : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D normal_tex_2 : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D depth_texture : hint_depth_texture, filter_linear_mipmap;

uniform vec3 deep_color : source_color = vec3(0.01, 0.08, 0.18);
uniform vec3 shallow_color : source_color = vec3(0.1, 0.45, 0.55);
uniform float depth_distance : hint_range(0.1, 10.0) = 2.0;

uniform float proximity_fade_distance : hint_range(0.1, 5.0) = 0.5;

uniform float wave_speed : hint_range(0.0, 0.5) = 0.03;
uniform float wave_scale : hint_range(0.1, 20.0) = 4.0;
uniform float normal_strength : hint_range(0.0, 5.0) = 0.8;
uniform float wave_height : hint_range(0.0, 2.0) = 0.15;

uniform float roughness : hint_range(0.0, 1.0) = 0.05;
uniform float metallic : hint_range(0.0, 1.0) = 0.1;

varying vec3 world_position;

void vertex() {
	// Calculate world position for seamless tiling across multiple meshes
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec2 world_uv = world_position.xz * (wave_scale * 0.1);

	// Multi-directional scrolling for displacement
	vec2 scroll1 = world_uv + TIME * wave_speed;
	vec2 scroll2 = world_uv - TIME * wave_speed * 0.8;

	// Read from normal maps to drive vertex displacement (using R channel as height)
	float n1 = texture(normal_tex_1, scroll1).r;
	float n2 = texture(normal_tex_2, scroll2).g;
	float wave = (n1 + n2) * 0.5;

	VERTEX.y += wave * wave_height;
}

void fragment() {
	// --- DEPTH & PROXIMITY FADE CALCULATIONS ---
	// Get linear depth of the scene background
	float depth_raw = textureLod(depth_texture, SCREEN_UV, 0.0).r;
	vec4 upos = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, depth_raw, 1.0);
	vec3 pixel_position = upos.xyz / upos.w;
	
	// Distance from water surface to the terrain beneath it
	float depth_diff = pixel_position.z - VERTEX.z;
	
	// Proximity fade factor (0.0 at shore, 1.0 in deep water)
	float prox_fade = clamp(depth_diff / proximity_fade_distance, 0.0, 1.0);
	
	// Depth tinting factor
	float depth_mask = clamp(depth_diff / depth_distance, 0.0, 1.0);

	// --- NORMALS & SCROLLING ---
	vec2 uv = world_position.xz * (wave_scale * 0.1);

	vec2 scroll_1 = uv + vec2(TIME * wave_speed, TIME * wave_speed * 0.5);
	vec2 scroll_2 = uv - vec2(TIME * wave_speed * 0.4, TIME * wave_speed * 0.8);

	// Unpack normal maps (Assuming Godot's default Hint_Normal texture setup)
	vec3 normal1 = texture(normal_tex_1, scroll_1).rgb * 2.0 - 1.0;
	vec3 normal2 = texture(normal_tex_2, scroll_2).rgb * 2.0 - 1.0;

	// Blend the two normal maps together
	vec3 blended_normal = normalize(vec3(normal1.xy + normal2.xy, normal1.z));
	blended_normal.xy *= normal_strength;

	// CRITICAL: Ensure normal is normalized and pointing up relative to the surface
	NORMAL = normalize(blended_normal);

	// --- LIGHTING & FRESNEL ---
	// Fresnel effect: higher reflectivity at flat viewing angles
	float fresnel = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	
	// Color interpolation based on terrain depth
	vec3 water_color = mix(shallow_color, deep_color, depth_mask);

	// --- OUTPUTS ---
	ALBEDO = water_color;
	METALLIC = metallic;
	// Make it slightly shinier at glancing angles via roughness reduction
	ROUGHNESS = mix(roughness, roughness * 0.5, fresnel); 
	SPECULAR = 0.5 + fresnel * 0.5;
	
	// Apply proximity fade to Alpha channel
	ALPHA = prox_fade;
	ALPHA = 1.0;
}