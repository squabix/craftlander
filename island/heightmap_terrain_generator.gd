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

func _ready() -> void:
	if generate_on_ready:
		await get_tree().process_frame
		generate()

func shader_set(parameter: String, to: Variant) -> void:
	if mesh_instance == null:
		printerr(self, " cannot set shader parameter without mesh instance")
		return
	if mesh_instance.material_override == null:
		printerr(self, " cannot set shader parameter without mesh instance material override")
		return
	
	mesh_instance.material_override.set_shader_parameter(
		parameter,
		to
	)

func shader_get(parameter: String) -> Variant:
	if mesh_instance == null:
		printerr(self, " cannot set shader parameter without mesh instance")
		return
	if mesh_instance.material_override == null:
		printerr(self, " cannot set shader parameter without mesh instance material override")
		return
	
	return mesh_instance.material_override.get_shader_parameter(
		parameter
	)

func add_new_mesh() -> void:
	mesh_instance.mesh = PlaneMesh.new()
	mesh_instance.mesh.size = Vector2(map_size.x, map_size.z)
	mesh_instance.mesh.subdivide_width = map_resolution.x
	mesh_instance.mesh.subdivide_depth = map_resolution.y
	mesh = mesh_instance.mesh

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
	shader_set("albedo_texture", image_texture)
	return image_texture

func calculate_single_normal(x: int, y: int, dx: float, dy: float) -> Vector3:
	var x0 := clampi(x - 1, 0, map_resolution.x - 1)
	var x1 := clampi(x + 1, 0, map_resolution.x - 1)
	var y0 := clampi(y - 1, 0, map_resolution.y - 1)
	var y1 := clampi(y + 1, 0, map_resolution.y - 1)
	
	var h_l: float = sample_heightmap.call(x0, y) * map_size.y
	var h_r: float = sample_heightmap.call(x1, y) * map_size.y
	var h_d: float = sample_heightmap.call(x, y0) * map_size.y
	var h_u: float = sample_heightmap.call(x, y1) * map_size.y
	
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


func update_collision_shape(image_texture: ImageTexture=null) -> void:
	if not is_instance_valid(collision_shape):
		return
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

func place_node(node: Node3D, px: int, py: int, normal_conformity := 1.0) -> void:
	node.global_position = get_pixel_position(px, py)
	align_node_to_normal.call_deferred(node, px, py, normal_conformity)

func get_pixel_position(x: int, y: int) -> Vector3:
	return global_transform * Vector3(
		(float(x) / float(map_resolution.x - 1)) * map_size.x - map_size.x / 2.0,
		sample_heightmap.call(x, y) * map_size.y,
		(float(y) / float(map_resolution.y - 1)) * map_size.z - map_size.z / 2.0
	)
