@tool
class_name HeightMapTerrainGenerator
extends Node3D

signal generated

@export_tool_button("Generate", "Noise") var generate_action: Callable = generate

@export var mesh_instance: MeshInstance3D
@export var collision_shape: CollisionShape3D
@export var generate_on_ready := true

@export_group("Map Measurements", "map")
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var map_size := Vector3(1, 1, 1)
@export_custom(PROPERTY_HINT_NONE, "suffix:px") var map_resolution := Vector2i(1, 1)

var mesh: PlaneMesh
var heightmap_sampler: Callable:
	get:
		if not heightmap_sampler.is_valid():
			heightmap_sampler = get_heightmap_sampler((shader_get(&"heightmap") as ImageTexture).get_image())
		return heightmap_sampler


func _ready() -> void:
	if generate_on_ready:
		generate.call_deferred()


func shader_set(parameter: StringName, to: Variant) -> void:
	if mesh_instance == null or mesh_instance.material_override == null:
		return
	mesh_instance.material_override.set_shader_parameter(parameter, to)


func shader_get(parameter: StringName) -> Variant:
	if mesh_instance == null or mesh_instance.material_override == null:
		return null
	return mesh_instance.material_override.get_shader_parameter(parameter)


func add_new_mesh() -> void:
	mesh_instance.mesh = PlaneMesh.new()
	mesh_instance.mesh.size = Vector2(map_size.x, map_size.z)
	mesh_instance.mesh.subdivide_width = map_resolution.x
	mesh_instance.mesh.subdivide_depth = map_resolution.y
	mesh = mesh_instance.mesh


func create_empty_image() -> Image:
	return Image.create_empty(map_resolution.x, map_resolution.y, false, Image.FORMAT_L8)


func update_shader_texture(image: Image) -> ImageTexture:
	var image_texture := ImageTexture.create_from_image(image)
	shader_set(&"heightmap", image_texture)
	shader_set(&"max_height", map_size.y)
	shader_set(&"albedo_texture", image_texture)
	return image_texture


func calculate_single_normal(x: int, y: int, dx: float, dy: float) -> Vector3:
	var x0 := clampi(x - 1, 0, map_resolution.x - 1)
	var x1 := clampi(x + 1, 0, map_resolution.x - 1)
	var y0 := clampi(y - 1, 0, map_resolution.y - 1)
	var y1 := clampi(y + 1, 0, map_resolution.y - 1)

	var h_l: float = heightmap_sampler.call(x0, y) * map_size.y
	var h_r: float = heightmap_sampler.call(x1, y) * map_size.y
	var h_d: float = heightmap_sampler.call(x, y0) * map_size.y
	var h_u: float = heightmap_sampler.call(x, y1) * map_size.y

	# Horizontal and vertical rate of change
	var dhdx := (h_r - h_l) / dx
	var dhdy := (h_u - h_d) / dy

	return Vector3(-dhdx, 2.0, -dhdy)


func get_pixel_normal(x: int, y: int, radius: int = 2) -> Vector3:
	var dx := map_size.x / float(map_resolution.x - 1)
	var dy := map_size.z / float(map_resolution.y - 1)

	var normal_sum := Vector3.ZERO
	var count := 0

	# Sample a square region of size (radius*2+1)^2
	for oy in range(-radius, radius + 1):
		for ox in range(-radius, radius + 1):
			var sx := clampi(x + ox, 0, map_resolution.x - 1)
			var sy := clampi(y + oy, 0, map_resolution.y - 1)
			normal_sum += calculate_single_normal(sx, sy, dx, dy).normalized()
			count += 1

	if count == 0:
		return Vector3.UP

	return (global_transform.basis * (normal_sum / count).normalized()).normalized()


func update_collision_shape(image_texture: ImageTexture = null) -> void:
	if not is_instance_valid(collision_shape):
		push_error("%s cannot update invalid collision shape")
		return

	if image_texture == null:
		image_texture = shader_get(&"heightmap")

	var image := image_texture.get_image()
	image.convert(Image.FORMAT_RF)

	var shape := get_heightmap_shape(image)

	collision_shape.shape = shape
	collision_shape.scale.x = mesh.size.x / image.get_width()
	collision_shape.scale.z = mesh.size.y / image.get_height()


func get_heightmap_shape(image: Image) -> HeightMapShape3D:
	var shape := HeightMapShape3D.new()
	shape.update_map_data_from_image(image, 0.0, map_size.y)
	return shape


func align_node_to_normal(node: Node3D, px: int, py: int, conformity := 1.0) -> void:
	var target_normal := get_pixel_normal(px, py).normalized()
	var current_basis := node.global_transform.basis

	# Calculate a new right (X) and forward (Z) vector based on the new normal (Y)
	var current_forward := -current_basis.z.normalized()

	var target_right := current_forward.cross(target_normal).normalized()
	var target_forward := target_normal.cross(target_right).normalized()

	# Create the fully aligned target basis
	var target_basis := Basis(target_right, target_normal, -target_forward)

	# Smoothly blend between the completely upright orientation and aligned orientation
	if conformity < 1.0:
		var upright_basis := Basis.from_euler(Vector3(0, current_basis.get_euler().y, 0))
		target_basis = upright_basis.slerp(target_basis, conformity) # Slerp between upright and fully aligned

	# Apply the new basis back to the node, preserving its scale
	node.global_transform.basis = target_basis.orthonormalized().scaled(current_basis.get_scale())


func place_node(node: Node3D, px: int, py: int, normal_conformity := 1.0, callback := Callable()) -> void:
	node.global_position = get_pixel_position(px, py)
	align_node_to_normal.call_deferred(node, px, py, normal_conformity)
	if callback.is_valid():
		callback.call()


func resize_to_resolution(image: Image) -> Image:
	image.resize(map_resolution.x, map_resolution.y, Image.INTERPOLATE_LANCZOS)
	return image


func get_heightmap_sampler(image: Image) -> Callable:
	return func(x: int, y: int) -> float: return image.get_pixel(x, y).r


func get_pixel_position(x: int, y: int) -> Vector3:
	return global_transform * Vector3(
		(float(x) / float(map_resolution.x - 1)) * map_size.x - map_size.x / 2.0,
		heightmap_sampler.call(x, y) * map_size.y,
		(float(y) / float(map_resolution.y - 1)) * map_size.z - map_size.z / 2.0,
	)

func generate() -> void:
	add_new_mesh()
	WorkerThreadPool.add_task(_generate_heightmap_image)


func _generate_heightmap_image() -> void:
	_finalize_generation.call_deferred(create_empty_image())


func _finalize_generation(output_image: Image) -> void:
	heightmap_sampler = get_heightmap_sampler(output_image)
	var image_texture := update_shader_texture(output_image)
	update_collision_shape(image_texture)
	generated.emit()
