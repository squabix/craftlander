@tool
extends HeightMapTerrainGenerator

const WARP_SAMPLE_OFFSET := 2000.0

@export var noise_textures: Array[Texture2D]
@export var taper_gradient_texture: GradientTexture2D
@export var absolute_gradient_texture: GradientTexture2D
@export var seed_override := 0

@export_group("Settings")
@export var taper_gradient_strength := 0.9
@export_range(0.0, 200.0, 0.5, "suffix:px") var domain_warp_max_strength := 50.0
@export var domain_warp_mask_texture: GradientTexture2D
@export_range(0.0, 1.0) var ridged_noise_influence := 0.4
@export var taper_power := 2.0
@export var beach_flattening := 2.0

@export_subgroup("Land Continuity")
@export var filter_isolated_landmasses := true
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var water_threshold := 0.0

var texture_images: Dictionary[Texture2D, Image] = { }
var noise_weights: Dictionary[FastNoiseLite, float] = { }


func _ready() -> void:
	if generate_on_ready and not Engine.is_editor_hint():
		generate.call_deferred()


func is_missing_textures() -> bool:
	return (
			noise_textures.is_empty()
			or taper_gradient_texture == null
			or absolute_gradient_texture == null
			or domain_warp_mask_texture == null
	)


func get_valid_textures() -> Array[Texture2D]:
	var all_textures: Array[Texture2D] = [
		taper_gradient_texture,
		absolute_gradient_texture,
		domain_warp_mask_texture,
	]
	var valid: Array[Texture2D]
	valid.assign(all_textures.filter(func(texture: Texture2D) -> bool: return texture != null))
	return valid


func load_image_textures() -> Dictionary[Texture2D, Image]:
	var loaded_texture_images: Dictionary[Texture2D, Image]
	for texture in get_valid_textures():
		loaded_texture_images[texture] = resize_to_resolution(texture.get_image())
	return loaded_texture_images


func seed_noise_textures() -> void:
	noise_weights = { }

	var effective_seed := seed_override if seed_override != 0 else Main.base_seed
	var hash_offset := Main.current_level_index

	for i in noise_textures.size():
		var texture = noise_textures[i]
		if not texture is NoiseTexture2D:
			Util.node_error("%s cannot seed invalid noise texture (%s) at index %s", self, texture, i)
			continue

		if not texture.noise is FastNoiseLite:
			Util.node_error("%s cannot seed invalid noise (%s) at index %s", self, texture.noise, i)
			continue

		var noise: FastNoiseLite = texture.noise.duplicate()
		noise.seed = effective_seed + hash_offset + i

		var color_ramp := (texture as NoiseTexture2D).color_ramp

		noise_weights[noise] = 1.0 if color_ramp == null else 1.0 - color_ramp.get_color(0).r


func generate() -> void:
	if is_missing_textures():
		Util.node_error("%s is missing required textures to generate", self)
		_finalize_generation.call_deferred(create_empty_image())
		return
	texture_images = load_image_textures()
	seed_noise_textures()
	super()


func _generate_heightmap_image() -> void:
	var heightmap_image := create_empty_image()
	var taper_gradient_image: Image = texture_images[taper_gradient_texture]
	var absolute_gradient_image: Image = texture_images[absolute_gradient_texture]
	var warp_mask_image: Image = texture_images[domain_warp_mask_texture]

	# Cache dimensions and configurations locally
	var map_resolution_x := map_resolution.x
	var map_resolution_y := map_resolution.y

	# Extract noise objects into a strongly typed local array for thread-safe iteration
	var local_noise_list: Array[FastNoiseLite]
	local_noise_list.assign(noise_weights.keys())

	var noises_count := local_noise_list.size()
	var noises_count_float := float(noises_count)
	var has_noise := noises_count > 0

	var _domain_warp_max_strength := domain_warp_max_strength
	var do_warp := domain_warp_mask_texture != null and _domain_warp_max_strength > 0.0 and has_noise
	var _ridged_noise_influence := ridged_noise_influence
	var _taper_power := taper_power
	var _beach_flattening := beach_flattening
	var _taper_gradient_strength := taper_gradient_strength
	var _noise_weights := noise_weights
	var _warp_sample_offset := WARP_SAMPLE_OFFSET

	for x in map_resolution_x:
		for y in map_resolution_y:
			var sampled_x := x
			var sampled_y := y

			# Warp domain by distorting grid coordinates so features look organic
			# Instead of sampling at (x, y), sample at (x + dx, y + dy)
			if do_warp:
				var warp_strength := warp_mask_image.get_pixel(x, y).r * _domain_warp_max_strength
				if warp_strength > 0.0:
					var first_noise := local_noise_list[0]
					var first_weight := _noise_weights[first_noise]

					# Convert the 0.0-1.0 scalar into a full 360-degree radian angle: θ = noise * 2π
					var angle := atan2(first_noise.get_noise_2d(float(x) + _warp_sample_offset, float(y) + _warp_sample_offset), first_noise.get_noise_2d(float(x), float(y)))

					# Calculate delta offsets scaled by local spatial weight
					# dx = sin(θ) * local_strength, dy = cos(θ) * local_strength
					sampled_x = clampi(x + int(sin(angle) * warp_strength * first_weight), 0, map_resolution_x - 1)
					sampled_y = clampi(y + int(cos(angle) * warp_strength * first_weight), 0, map_resolution_y - 1)

			var base_noise := 0.0

			for i in noises_count:
				var noise := local_noise_list[i]
				var weight := _noise_weights[noise]
				var raw_noise := (1.0 - weight) + ((noise.get_noise_2d(float(sampled_x), float(sampled_y)) + 1.0) / 2.0 * weight)

				# Blend raw noise with ridged noise
				# Ridged Noise Equation: f(x) = 1.0 - abs(noise - 0.5) * 2.0
				base_noise += raw_noise + (1.0 - absf(raw_noise - 0.5) * 2.0 - raw_noise) * _ridged_noise_influence

			if has_noise:
				base_noise /= noises_count_float

			# Taper the terrain downwards the further it gets from the center
			var taper := taper_gradient_image.get_pixel(sampled_x, sampled_y).r
			var value := base_noise - (pow(1.0 - taper, _taper_power) * _taper_gradient_strength)

			# Eliminate cliff edges at sea level
			if _beach_flattening > 1.0:
				value *= pow(taper, _beach_flattening)

			# Absolute constraints
			var abs_value := absolute_gradient_image.get_pixel(sampled_x, sampled_y).r
			if value > abs_value:
				value = abs_value

			value = clampf(value, 0.0, 1.0)
			heightmap_image.set_pixel(x, y, Color(value, value, value))

	if filter_isolated_landmasses:
		_remove_isolated_landmasses(heightmap_image)
	_finalize_generation.call_deferred(heightmap_image)


func _remove_isolated_landmasses(image: Image) -> void:
	var width := image.get_width()
	var height := image.get_height()

	var visited := PackedByteArray()
	visited.resize(width * height)
	visited.fill(0)

	var landmasses: Array[Array] = [] # Array of arrays of indices representing each landmass
	var threshold := water_threshold

	for y in height:
		for x in width:
			var index := y * width + x
			if visited[index] == 1:
				continue

			if image.get_pixel(x, y).r <= threshold:
				continue

			var current_landmass := PackedInt32Array()
			var queue: Array[int] = [index]
			visited[index] = 1

			while queue.size() > 0:
				var current: int = queue.pop_back()
				current_landmass.append(current)
				var current_x := current % width
				var current_y := current / width

				# Check 4-way neighbors safely
				# Left
				if current_x > 0:
					var n_index := current - 1
					if visited[n_index] == 0 and image.get_pixel(current_x - 1, current_y).r > threshold:
						visited[n_index] = 1
						queue.append(n_index)
				# Right
				if current_x < width - 1:
					var n_index := current + 1
					if visited[n_index] == 0 and image.get_pixel(current_x + 1, current_y).r > threshold:
						visited[n_index] = 1
						queue.append(n_index)
				# Up
				if current_y > 0:
					var n_index := current - width
					if visited[n_index] == 0 and image.get_pixel(current_x, current_y - 1).r > threshold:
						visited[n_index] = 1
						queue.append(n_index)
				# Down
				if current_y < height - 1:
					var n_index := current + width
					if visited[n_index] == 0 and image.get_pixel(current_x, current_y + 1).r > threshold:
						visited[n_index] = 1
						queue.append(n_index)
			landmasses.append(current_landmass)

	if landmasses.is_empty():
		return

	# Determine largest landmass
	var main_landmass_index := 0
	var max_size := 0

	for i in landmasses.size():
		if landmasses[i].size() > max_size:
			max_size = landmasses[i].size()
			main_landmass_index = i

	# Erase smaller landmasses
	for i in landmasses.size():
		if i == main_landmass_index:
			continue
		for flat_index in landmasses[i]:
			image.set_pixel(flat_index % width, flat_index / width, Color.BLACK)


func _finalize_generation(heightmap_image: Image) -> void:
	super(heightmap_image)
	EventBus.trigger(&"island_terrain_generated")
