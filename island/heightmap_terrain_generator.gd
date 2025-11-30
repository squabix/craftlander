@tool
extends Node3D
class_name HeightmapTerrainGenerator

signal updated_mesh

@export_tool_button("Update Mesh")
var update_texture_action: Callable = update_mesh

@export var map_size: Vector3
@export var map_resolution: Vector2i
@export var mesh_instance: MeshInstance3D
@export var collision_shape: CollisionShape3D
@export var generate_on_ready: bool = true

var mesh: PlaneMesh
var sample_heightmap: Callable

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
	if generate_on_ready:
		await get_tree().process_frame
		generate()

func get_mesh_heightmap_texture() -> ImageTexture:
	return mesh_instance.material_override.get_shader_parameter("heightmap")

func generate() -> void:
	add_new_mesh()
	var image_texture: ImageTexture = update_shader_texture()
	update_collision_shape(image_texture)

func update_mesh() -> void:
	add_new_mesh()
	update_shader_texture()
	updated_mesh.emit()

func update_shader_texture() -> ImageTexture:
	var image_texture: ImageTexture = generate_image_texture()
	shader_set("heightmap", image_texture)
	shader_set("max_height", map_size.y)
	mesh_instance.material_override.set_shader_parameter(
		"albedo_texture",
		image_texture
	)
	return image_texture

func get_pixel_normal(x: int, y: int) -> Vector3:

	# Clamp pixels so we can sample neighbors safely
	var x0 := clampi(x - 1, 0, map_resolution.x - 1)
	var x1 := clampi(x + 1, 0, map_resolution.x - 1)
	var y0 := clampi(y - 1, 0, map_resolution.y - 1)
	var y1 := clampi(y + 1, 0, map_resolution.y - 1)

	# Sample heights (L8 format: r channel holds height 0..1)
	var h_l: float = sample_heightmap.call(x0, y) * map_size.y   # left
	var h_r: float = sample_heightmap.call(x1, y) * map_size.y   # right
	var h_d: float = sample_heightmap.call(x, y0) * map_size.y   # down
	var h_u: float = sample_heightmap.call(x, y1) * map_size.y   # up

	# World-space pixel spacing on X/Z
	var dx := map_size.x / float(map_resolution.x - 1)
	var dy := map_size.z / float(map_resolution.y - 1)

	# Compute derivatives
	var dhdx := (h_r - h_l) / dx
	var dhdy := (h_u - h_d) / dy

	# Construct normal in object-local space
	var normal := Vector3(-dhdx, 2.0, -dhdy).normalized()

	# Convert to world space
	return (global_transform.basis * normal).normalized()

func update_collision_shape(image_texture: ImageTexture) -> void:
	var image: Image = image_texture.get_image()
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
	# 1. Position on heightmap
	var pos := get_pixel_position(px, py)
	node.global_position = pos

	# 2. Get terrain normal
	var normal := get_pixel_normal(px, py).normalized()

	# 3. Preserve the node's current forward direction
	var forward := node.global_transform.basis.z.normalized()

	# If forward is almost parallel to normal, use a fallback direction
	if abs(forward.dot(normal)) > 0.99:
		forward = Vector3.FORWARD

	print("Forward: ", forward)
	print("Normal: ", normal)

	# 4. Use look_at to align node's UP to the terrain normal
	# "at" = position + forward direction
	# "up" = terrain normal
	node.look_at(node.global_position + forward, normal)
	
	print("Rot degrees: ", node.rotation_degrees)



func get_pixel_position(x: int, y: int) -> Vector3:
	return global_transform * Vector3(
		(float(x) / float(map_resolution.x - 1)) * map_size.x - map_size.x / 2.0,
		sample_heightmap.call(x, y) * map_size.y,
		(float(y) / float(map_resolution.y - 1)) * map_size.z - map_size.z / 2.0
	)
