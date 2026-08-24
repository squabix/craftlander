shader_type spatial;
render_mode blend_mix, depth_draw_always, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 albedo : source_color = vec4(1.0);
uniform vec4 emission_color : source_color = vec4(0.0, 1.0, 1.0, 1.0);
uniform sampler2D texture_albedo : source_color;
uniform float emission_amount : hint_range(0.0, 16.0) = 5.0;
uniform float rim_steepness : hint_range(0.0, 16.0) = 3.0;
uniform vec3 uv_scale = vec3(1.0, 1.0, 1.0);
uniform vec3 uv_offset = vec3(0.0, 0.0, 0.0);

uniform float model_height = 2.0;
uniform float dissolve_start : hint_range(0.0, 1.0) = 0.0;
uniform float dissolve_length : hint_range(0.0, 1.0) = 1.0;
uniform float gradient_bias : hint_range(0.1, 5.0) = 1.0;

uniform float wave_speed : hint_range(0.0, 10.0) = 2.0;
uniform float wave_amplitude : hint_range(0.0, 0.5) = 0.08;
uniform float wave_frequency : hint_range(0.1, 10.0) = 3.0;
uniform sampler2D noise_texture : hint_default_white;
uniform float noise_distortion : hint_range(0.0, 0.5) = 0.05;
uniform vec2 noise_flow_speed = vec2(0.0, -0.5);

varying float vert_height;
varying vec2 noise_uv;

void vertex() {
	UV = UV * uv_scale.xy + uv_offset.xy;
	
	// Normalize Y position relative to height
	vert_height = (VERTEX.y + (model_height / 2.0)) / model_height;
	
	// Organic wave displacement (weighted more towards the feet/tail)
	float feet_weight = 1.0 - clamp(vert_height, 0.0, 1.0);
	float wave_x = sin(TIME * wave_speed + VERTEX.y * wave_frequency);
	float wave_z = cos(TIME * wave_speed * 0.8 + VERTEX.y * wave_frequency);
	VERTEX.x += wave_x * wave_amplitude * feet_weight;
	VERTEX.z += wave_z * wave_amplitude * feet_weight;
	
	// Animate noise UV coords vertically
	noise_uv = UV + noise_flow_speed * TIME;
}

void fragment() {
	// Sample floating noise texture
	vec4 noise_val = texture(noise_texture, noise_uv);
	
	// Distort standard UVs with noise for wispy fluid warping
	vec2 distorted_uv = UV + (noise_val.rg - 0.5) * noise_distortion;
	
	// Base ALBEDO and EMISSION with UV warping
	vec4 albedo_tex = texture(texture_albedo, distorted_uv);
	ALBEDO = albedo.rgb * albedo_tex.rgb;
	
	// Rim / Fresnel calculation
	float NdotV = dot(NORMAL, VIEW);
	float rim_light = pow(1.0 - clamp(NdotV, 0.0, 1.0), rim_steepness);
	float base_alpha = rim_light * emission_color.a / PI;
	
	// Vertical transparency mask
	float height_factor = clamp((vert_height - dissolve_start) / max(dissolve_length, 0.0001), 0.0, 1.0);
	float height_fade = pow(height_factor, gradient_bias);
	
	// Modulate emission with noise flow for dynamic energy flicker
	EMISSION = emission_color.rgb * emission_amount * mix(0.7, 1.3, noise_val.r);
	
	// Combine rim, height gradient, texture mask, and wispy noise breakups
	ALPHA = base_alpha * height_fade * noise_val.r;
}