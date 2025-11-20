@tool
extends HeightmapTerrainGenerator

@export var noise_textures: Array[Texture2D]
@export var taper_gradient_texture: GradientTexture2D
@export var taper_gradient_strength: float = 0.9
@export var absolute_gradient_texture: GradientTexture2D
@export var heightmap_rect: TextureRect

func _ready() -> void:
	await super()
	heightmap_rect.texture = get_mesh_heightmap_texture()

func get_pixel(x: int, y: int, texture_images: Dictionary[Texture2D, Image]) -> Color:
	var sample: Callable = func(texture: Texture2D) -> float: return texture_images[texture].get_pixel(x, y).r
	
	var value: float = 0.0
	
	for texture in noise_textures:
		value += sample.call(texture)
	value /= float(len(noise_textures))
	
	value -= (1.0 - sample.call(taper_gradient_texture)) * taper_gradient_strength
	value = min(value, sample.call(absolute_gradient_texture))
	
	return Color(value, value, value)

func load_image_textures() -> Dictionary[Texture2D, Image]:
	var textures: Array[Texture2D] = [
		taper_gradient_texture,
		absolute_gradient_texture
	]
	textures.append_array(noise_textures)
	
	var loaded_texture_images: Dictionary[Texture2D, Image]
	for texture in textures:
		loaded_texture_images[texture] = texture.get_image()
	return loaded_texture_images

func generate_image_texture() -> ImageTexture:
	var texture_images: Dictionary[Texture2D, Image] = load_image_textures()
	
	# Resize all images to same size
	for image in texture_images.values():
		image.resize(map_resolution.x, map_resolution.y)
	
	var output_image: Image = Image.create_empty(
		map_resolution.x,
		map_resolution.y,
		false,
		Image.FORMAT_L8
	)
	
	for x in map_resolution.x:
		for y in map_resolution.y:
			output_image.set_pixel(x, y, get_pixel(x, y, texture_images))
	
	return ImageTexture.create_from_image(output_image)
