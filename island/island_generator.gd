@tool
extends HeightmapTerrainGenerator

@export var noise_textures: Array[Texture2D]
@export var taper_gradient_texture: GradientTexture2D
@export var taper_gradient_strength := 0.9
@export var absolute_gradient_texture: GradientTexture2D

func is_missing_textures() -> bool:
	if noise_textures.is_empty():
		return true
	if taper_gradient_texture == null:
		return true
	if absolute_gradient_texture == null:
		return true
	return false

func generate_image_texture() -> ImageTexture:
	var output_image := create_empty_image()
	
	if is_missing_textures():
		printerr(self, " is missing required textures to generate")
		return ImageTexture.create_from_image(output_image) # Return empty output image texture
	
	var texture_images := load_image_textures()
	
	for x in map_resolution.x:
		for y in map_resolution.y:
			output_image.set_pixel(x, y, get_pixel(x, y, texture_images))
	
	sample_heightmap = get_sample_heightmap_callable(output_image)
	
	return ImageTexture.create_from_image(output_image)

func get_pixel(x: int, y: int, texture_images: Dictionary[Texture2D, Image]) -> Color:
	var sample := func(texture: Texture2D) -> float: return texture_images[texture].get_pixel(x, y).r
	
	var value := 0.0
	
	# Combine noise textures
	for texture in noise_textures:
		value += sample.call(texture)
	value /= float(len(noise_textures))
	
	value -= (1.0 - sample.call(taper_gradient_texture)) * taper_gradient_strength
	value = min(value, sample.call(absolute_gradient_texture))
	
	return Color(value, value, value)

func load_image_textures() -> Dictionary[Texture2D, Image]:
	var all_textures: Array[Texture2D] = [
		taper_gradient_texture,
		absolute_gradient_texture
	]
	all_textures.append_array(noise_textures)
	
	var filtered_textures := all_textures.filter(func(t): return t != null)
	
	var loaded_texture_images: Dictionary[Texture2D, Image]
	for texture in filtered_textures:
		loaded_texture_images[texture] = resize_to_resolution(texture.get_image())
	return loaded_texture_images

func resize_to_resolution(image: Image) -> Image:
	image.resize(map_resolution.x, map_resolution.y, Image.INTERPOLATE_LANCZOS)
	return image

func create_empty_image() -> Image:
	return Image.create_empty(
		map_resolution.x,
		map_resolution.y,
		false,
		Image.FORMAT_L8
	)

func get_sample_heightmap_callable(image: Image) -> Callable:
	return func(x: int, y: int) -> float: return image.get_pixel(x, y).r
