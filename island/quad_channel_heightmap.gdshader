shader_type spatial;

uniform sampler2D albedo_texture;
uniform sampler2D heightmap;
uniform float height_ratio;

void vertex() {
	VERTEX.y += texture(heightmap, UV).r * height_ratio;
}

void fragment() {
	ALBEDO = texture(albedo_texture, UV).rgb;
}
