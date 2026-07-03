@tool
extends HeightmapTerrainGenerator

@export var noise_textures: Array[Texture2D]
@export var taper_gradient_texture: GradientTexture2D
@export var absolute_gradient_texture: GradientTexture2D

@export_group("Settings")
@export var taper_gradient_strength := 0.9
@export_range(0.0, 100.0, 0.5, "suffix:px") var domain_warp_strength := 15.0
@export_range(0.0, 1.0) var ridged_noise_influence := 0.4
@export var taper_power := 2.0
@export_range(1.0, 5.0, 0.1) var beach_flattening := 2.0


func is_missing_textures() -> bool:
	return noise_textures.is_empty() or taper_gradient_texture == null or absolute_gradient_texture == null


func generate_image_texture() -> ImageTexture:
	var output_image := create_empty_image()

	if is_missing_textures():
		printerr(self, " is missing required textures to generate")
		return ImageTexture.create_from_image(output_image)

	var texture_images := load_image_textures()

	# Extract direct object references here to store them on the local stack in order to reduce lookups
	var taper_gradient_image: Image = texture_images[taper_gradient_texture]
	var absolute_gradient_image: Image = texture_images[absolute_gradient_texture]

	var noise_imgs: Array[Image] = []
	for tex in noise_textures:
		if tex in texture_images:
			noise_imgs.append(texture_images[tex])

	# Cache dimensions and configurations locally because local register access in GDScript is faster
	var map_resolution_x := map_resolution.x
	var map_resolution_y := map_resolution.y
	var noises_count := float(noise_imgs.size()) # Float for later division
	var has_noise := noises_count > 0.0

	var _domain_warp_strength := domain_warp_strength
	var do_warp := domain_warp_strength > 0.0 and has_noise
	var _ridged_noise_influence := ridged_noise_influence
	var _taper_power := taper_power
	var _beach_flattening := beach_flattening
	var _taper_gradient_strength := taper_gradient_strength

	for x in map_resolution_x:
		for y in map_resolution_y:
			var sampled_x := x
			var sampled_y := y

			# Warp domain by distorting grid coordinates so features look organic
			# Instead of sampling at (x, y), sample at (x + dx, y + dy)
			if do_warp:
				var warp_noise: float = noise_imgs[0].get_pixel(x, y).r

				# Convert the 0.0-1.0 scalar into a full 360-degree radian angle: θ = noise * 2π
				var angle := warp_noise * 6.28318530718

				# Calculate delta offsets
				# dx = sin(θ) * strength, dy = cos(θ) * strength
				var offset_x := sin(angle) * _domain_warp_strength
				var offset_y := cos(angle) * _domain_warp_strength

				# Displace original coordinates and clamp them within valid array boundaries
				sampled_x = clampi(x + int(offset_x), 0, map_resolution_x - 1)
				sampled_y = clampi(y + int(offset_y), 0, map_resolution_y - 1)

			# Noise blending and ridges
			var base_noise := 0.0
			for img in noise_imgs:
				var raw_noise := img.get_pixel(sampled_x, sampled_y).r

				# Ridged Noise Equation: f(x) = 1.0 - abs(noise - 0.5) * 2.0
				var ridged_noise := 1.0 - absf(raw_noise - 0.5) * 2.0

				# Blend raw noise with ridged noise
				base_noise += raw_noise + (ridged_noise - raw_noise) * _ridged_noise_influence

			if has_noise:
				base_noise /= noises_count

			# Goal: Taper the terrain downwards the further it gets from the center
			var taper_val := taper_gradient_image.get_pixel(sampled_x, sampled_y).r

			# Exponential Falloff Calculation: Falloff = (1.0 - taper_val)^power
			var falloff := pow(1.0 - taper_val, _taper_power)

			var value := base_noise - (falloff * _taper_gradient_strength)

			# Eliminate cliff edges at sea level
			if _beach_flattening > 1.0:
				value *= pow(taper_val, _beach_flattening)

			# Absolute constraints
			var abs_val := absolute_gradient_image.get_pixel(sampled_x, sampled_y).r
			if value > abs_val:
				value = abs_val

			value = clampf(value, 0.0, 1.0)
			output_image.set_pixel(x, y, Color(value, value, value))

	sample_heightmap = get_sample_heightmap_callable(output_image)

	return ImageTexture.create_from_image(output_image)


func generate() -> void:
	super()
	EventBus.trigger("island_terrain_generated")


func load_image_textures() -> Dictionary[Texture2D, Image]:
	var all_textures: Array[Texture2D] = [
		taper_gradient_texture,
		absolute_gradient_texture,
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
		Image.FORMAT_L8,
	)


func get_sample_heightmap_callable(image: Image) -> Callable:
	return func(x: int, y: int) -> float: return image.get_pixel(x, y).r
