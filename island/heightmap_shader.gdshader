shader_type spatial;

uniform sampler2D albedo_texture;
uniform sampler2D heightmap;
uniform float max_height;

void vertex() {
	VERTEX.y += texture(heightmap, UV).r * max_height;
}

void fragment() {
	ALBEDO = texture(albedo_texture, UV).rgb;
}
