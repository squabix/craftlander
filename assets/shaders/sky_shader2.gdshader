shader_type sky;

group_uniforms Sky;
uniform vec4 sky_day : source_color = vec4(0.0,0.3,0.7,1.0);
uniform vec4 horizon_day : source_color = vec4(0.75,0.85,0.85,1.0);
uniform vec4 horizon_sunset : source_color = vec4(0.9,0.4,0.1,1.0);
uniform vec4 sky_sunset : source_color = vec4(0.15, 0.2, 0.4, 1.0);
uniform vec4 horizon_night : source_color = vec4(0.1, 0.15, 0.2, 1.0);
uniform vec4 sky_night : source_color = vec4(0.05, 0.10, 0.15, 1.0);
uniform float day_night_mix : hint_range(-1.0, 1.0, 0.1) = 0.8;
uniform bool use_directional_light = true;
uniform float horizon_exponent = 2.0;
uniform float sunset_amount_exponent = 0.7;
uniform float night_amount_exponent = 4.0;

group_uniforms Clouds;
uniform sampler2D cloud_tex_01;
uniform sampler2D cloud_tex_02;
uniform vec4 cloud_color : source_color = vec4(0.8, 0.8, 0.8, 1.0);
uniform vec2 cloud_tiling = vec2(1.0);
uniform vec2 wind_speed = vec2(0.5);
uniform float cloud_density : hint_range(0.0, 5.0, 0.1) = 0.7;
uniform float cloud_depth = 2.0;
uniform float cloud_shape_exponent = 2.0;
uniform float cloud_occlude_exponent = 1.0;

group_uniforms Stars;
uniform sampler2D night_noise_01;
uniform sampler2D night_noise_02;

group_uniforms Sun;
uniform float sun_scale = 0.05;
uniform float sun_strength = 15.0;
uniform vec4 sun_color : source_color = vec4(1.0,0.9,0.0,1.0);

float plane_intersection(vec3 origin, vec3 normal, vec3 ray_start, vec3 ray_dir) {
	return dot(origin - ray_start, normal) / dot(ray_dir, normal);
}

float get_cloud_height(sampler2D tex, vec2 uv) {
	float height = texture(tex, uv).r;
	height = clamp((height - (1.0 - cloud_density)) / (cloud_density), 0.0, 1.0);
	return pow(height, cloud_shape_exponent);
}

void sky() {
	float t = plane_intersection(vec3(0.0, 1.0, 0.0), vec3(0.0, -1.0, 0.0), vec3(0.0), EYEDIR);
	
	float blend = day_night_mix;
	if(use_directional_light){
		blend = LIGHT0_DIRECTION.y;
	}

	vec3 sky = vec3(0.0);
	vec3 horizon_color = vec3(0.0);
	vec3 sky_color = vec3(0.0);

	float cloud_value = 0.0;
	if(t >= 0.0){
		vec3 wind = vec3(wind_speed.x, 0.0, wind_speed.y) * TIME * 0.1;
		vec3 tiling = vec3(cloud_tiling.x, 1.0, cloud_tiling.y) * 0.2;
		vec3 cloud_pos1 = EYEDIR * t * tiling + wind;
		vec3 cloud_pos2 = EYEDIR * t * tiling + (wind*0.5);

		float height1 = get_cloud_height(cloud_tex_01, cloud_pos1.xz);
		float height2 = get_cloud_height(cloud_tex_02, cloud_pos2.xz);
		cloud_pos1 += EYEDIR * height1 * cloud_depth * 0.1;
		cloud_pos2 += EYEDIR * height2 * cloud_depth * 0.1;
		height1 = get_cloud_height(cloud_tex_01,cloud_pos1.xz);
		height2 = get_cloud_height(cloud_tex_02,cloud_pos2.xz);
		cloud_value = min(height1, height1 * height2);

		cloud_value *= smoothstep(0.0, 0.2, EYEDIR.y);
	}

	float sun_distance = clamp(1.0 - distance(EYEDIR, LIGHT0_DIRECTION) - pow(cloud_value,cloud_occlude_exponent),0.0,1.0);
	float sun_disc = clamp(smoothstep(1.0 - sun_scale, 1.0, sun_distance), 0.0, 1.0);
	float sun_glow = clamp(0.0, 1.0, (pow(sun_distance, 4.0)*0.07));
	vec3 sun = mix(vec3(0.0), sun_color.rgb * sun_strength, max(sun_disc, sun_glow));

	float night_noise = texture(night_noise_02, (EYEDIR / ((1.0 - abs(t) * 0.05))).xz).r;
	float stars = smoothstep(0.9, .95, texture(night_noise_01, (EYEDIR / ((1.0 - abs(t) * 0.05))).xz).r);
	float night_blend = clamp(0.0,1.0,0.0 - blend);
	stars = clamp(clamp((stars - cloud_value * 2.0), 0.0, 1.0) * night_blend, 0.0, 1.0) + (night_noise*0.01);

	horizon_color = mix(horizon_sunset, horizon_day, clamp(blend,0.0,1.0)).rgb;
	horizon_color = mix(horizon_night.rgb, horizon_color, pow(clamp(1.0+blend,0.0,1.0), 4.0)).rgb;

	vec3 sky_night_mix = sky_night.rgb * (night_noise * 0.5 + 0.5);
	sky_color = mix(sky_sunset, sky_day, clamp(blend,0.0,1.0)).rgb;
	sky_color = mix(sky_night_mix, sky_color, clamp(pow(1.0+blend, 4.0),0.0,1.0)).rgb;

	sky = mix(sky_color, horizon_color, pow(1.0 - abs(EYEDIR.y), horizon_exponent));
	sky = mix(sky, cloud_color.rgb * 1.0, pow(cloud_value, 0.8));


	sky += stars * 1.0;

	sky = mix(sky, mix(sky_color * 0.5, horizon_color, EYEDIR.y + 1.0).rgb, clamp(pow(1.0 - EYEDIR.y, 2.0), 0.0, 1.0));
	if(use_directional_light) {
		sky += sun * clamp(pow(EYEDIR.y + 1.0, 16.0),0.0,1.0);
	}

	COLOR = sky;
}
