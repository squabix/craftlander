shader_type spatial;

uniform sampler2D albedo_texture;
uniform sampler2D heightmap;
uniform sampler2D gradient;
uniform float height_ratio;
uniform float gradient_strength;

void vertex() {
	VERTEX.y = -texture(gradient, UV - vec2(10, 10)).r * gradient_strength - texture(heightmap, UV).r * height_ratio;
}

void fragment() {
	ALBEDO = texture(albedo_texture, UV).rgb;
}
