@tool
extends Node3D

@export_tool_button("Update Mesh")
var update_texture_action: Callable = update_mesh

@export var map_size: Vector3
@export var map_resolution: Vector2i
@export var image_width: int
@export var image_height: int
@export var noise_textures: Array[Texture2D]
@export var taper_gradient_texture: GradientTexture2D
@export var taper_gradient_strength: float = 0.9
@export var absolute_gradient_texture: GradientTexture2D
@export var mesh_instance: MeshInstance3D
@export var collision_shape: CollisionShape3D
@export var heightmap_rect: TextureRect

var mesh: PlaneMesh

func shader_set(parameter: String, to: Variant) -> void:
	mesh_instance.material_override.set_shader_parameter(
		parameter,
		to
	)

func add_new_mesh() -> void:
	mesh_instance.mesh = PlaneMesh.new()
	mesh_instance.mesh.size = Vector2(map_size.x, map_size.z)
	mesh_instance.mesh.subdivide_width = map_resolution.x
	mesh_instance.mesh.subdivide_depth = map_resolution.y
	mesh = mesh_instance.mesh

func _ready() -> void:
	await get_tree().process_frame
	
	add_new_mesh()
	
	var image_texture: ImageTexture = update_shader_texture()
	heightmap_rect.texture = image_texture
	update_collision_shape(image_texture)

func update_mesh() -> void:
	add_new_mesh()
	var image_texture: ImageTexture = update_shader_texture()

func update_shader_texture() -> ImageTexture:
	var image_texture: ImageTexture = generate_image_texture()
	shader_set("heightmap", image_texture)
	shader_set("max_height", map_size.y)
	mesh_instance.material_override.set_shader_parameter(
		"albedo_texture",
		image_texture
	)
	return image_texture

func update_collision_shape(image_texture: ImageTexture) -> void:
	var img: Image = image_texture.get_image()
	img.convert(Image.FORMAT_RF)
	var shape := HeightMapShape3D.new()
	shape.update_map_data_from_image(img, 0.0, map_size.y)
	collision_shape.shape = shape
	collision_shape.scale.x = mesh.size.x / img.get_width()
	collision_shape.scale.z = mesh.size.y / img.get_height()
	print_debug("Scaled collision shape to " + str(collision_shape.scale))

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
		image.resize(image_width, image_height)
		print("Resized " + str(image) + " to " + str(image_width) + " x " + str(image_height))
	
	var output_image: Image = Image.create_empty(
		image_width,
		image_height,
		false,
		Image.FORMAT_L8
	)
	
	for x in image_width:
		for y in image_height:
			output_image.set_pixel(x, y, get_pixel(x, y, texture_images))
	
	return ImageTexture.create_from_image(output_image)
