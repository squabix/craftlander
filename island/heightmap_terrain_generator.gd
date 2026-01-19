@tool
extends Node3D
class_name HeightmapTerrainGenerator

signal updated_mesh

@export_tool_button("Update Mesh")
var update_texture_action: Callable = update_mesh

@export_tool_button("Generate Collision Shape")
var generate_collision_shape_action: Callable = update_collision_shape

@export var map_size := Vector3(1, 1, 1)
@export var map_resolution := Vector2i(1, 1)
@export var mesh_instance: MeshInstance3D
@export var collision_shape: CollisionShape3D
@export var generate_on_ready := true

var mesh: PlaneMesh
var sample_heightmap: Callable

func shader_set(parameter: String, to: Variant) -> void:
	mesh_instance.material_override.set_shader_parameter(
		parameter,
		to
	)

func shader_get(parameter: String) -> Variant:
	return mesh_instance.material_override.get_shader_parameter(
		parameter
	)

func add_new_mesh() -> void:
	mesh_instance.mesh = PlaneMesh.new()
	mesh_instance.mesh.size = Vector2(map_size.x, map_size.z)
	mesh_instance.mesh.subdivide_width = map_resolution.x
	mesh_instance.mesh.subdivide_depth = map_resolution.y
	mesh = mesh_instance.mesh

func _ready() -> void:
	if generate_on_ready:
		await get_tree().process_frame
		generate()

func get_mesh_heightmap_texture() -> ImageTexture:
	return mesh_instance.material_override.get_shader_parameter("heightmap")

func generate() -> void:
	add_new_mesh()
	var image_texture := update_shader_texture()
	update_collision_shape(image_texture)

func update_mesh() -> void:
	add_new_mesh()
	update_shader_texture()
	updated_mesh.emit()

func update_shader_texture() -> ImageTexture:
	var image_texture := generate_image_texture()
	shader_set("heightmap", image_texture)
	shader_set("max_height", map_size.y)
	mesh_instance.material_override.set_shader_parameter(
		"albedo_texture",
		image_texture
	)
	return image_texture

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

			# Neighbor samples for derivative at (sx, sy)
			var x0 := clampi(sx - 1, 0, map_resolution.x - 1)
			var x1 := clampi(sx + 1, 0, map_resolution.x - 1)
			var y0 := clampi(sy - 1, 0, map_resolution.y - 1)
			var y1 := clampi(sy + 1, 0, map_resolution.y - 1)

			var h_l: float = sample_heightmap.call(x0, sy) * map_size.y
			var h_r: float = sample_heightmap.call(x1, sy) * map_size.y
			var h_d: float = sample_heightmap.call(sx, y0) * map_size.y
			var h_u: float = sample_heightmap.call(sx, y1) * map_size.y

			var dhdx := (h_r - h_l) / dx
			var dhdy := (h_u - h_d) / dy

			var n := Vector3(-dhdx, 2.0, -dhdy).normalized()
			normal_sum += n
			count += 1

	if count == 0:
		return Vector3.UP

	var avg_normal := (normal_sum / count).normalized()
	return (global_transform.basis * avg_normal).normalized()


func update_collision_shape(image_texture: ImageTexture=null) -> void:
	if image_texture == null:
		image_texture = shader_get("heightmap")
	var image := image_texture.get_image()
	image.convert(Image.FORMAT_RF)
	var shape := HeightMapShape3D.new()
	shape.update_map_data_from_image(image, 0.0, map_size.y)
	collision_shape.shape = shape
	collision_shape.scale.x = mesh.size.x / image.get_width()
	collision_shape.scale.z = mesh.size.y / image.get_height()

func generate_image_texture() -> ImageTexture:
	return ImageTexture.create_from_image(
		Image.create_empty(
			map_resolution.x,
			map_resolution.y,
			false,
			Image.FORMAT_L8
		)
	)

func place_node(node: Node3D, px: int, py: int) -> void:
	var pos := get_pixel_position(px, py)
	node.global_position = pos
	var normal := get_pixel_normal(px, py).normalized()
	var forward := node.global_transform.basis.z.normalized()
	if abs(forward.dot(normal)) > 0.99:
		forward = Vector3.FORWARD
	node.look_at(node.global_position + forward, normal)

func get_pixel_position(x: int, y: int) -> Vector3:
	return global_transform * Vector3(
		(float(x) / float(map_resolution.x - 1)) * map_size.x - map_size.x / 2.0,
		sample_heightmap.call(x, y) * map_size.y,
		(float(y) / float(map_resolution.y - 1)) * map_size.z - map_size.z / 2.0
	)
