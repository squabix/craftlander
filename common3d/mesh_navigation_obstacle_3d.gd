@tool
class_name MeshNavigationObstacle3D
extends NavigationObstacle3D

@export var mesh_instance: MeshInstance3D:
	set(value):
		mesh_instance = value
		generate()
@export var generate_on_ready := false
@export var flip_winding_order: bool = false:
	set(value):
		flip_winding_order = value
		generate()

@export_tool_button("Regenerate", "ArrayMesh") var generate_action := generate


static func get_bottom_center(aabb: AABB) -> Vector3:
	return Vector3(
		aabb.position.x + (aabb.size.x / 2.0),
		aabb.position.y,
		aabb.position.z + (aabb.size.z / 2.0),
	)


func _ready() -> void:
	if generate_on_ready:
		generate()


func reset() -> void:
	vertices = PackedVector3Array()
	radius = 0.0
	height = 0.0


func generate() -> void:
	# Ensure the node is active in the scene tree before calculating relative transforms
	if not is_inside_tree():
		return

	if not mesh_instance or not mesh_instance.mesh:
		reset()
		return

	var mesh: Mesh = mesh_instance.mesh
	var instance_transform := mesh_instance.global_transform
	var local_aabb: AABB = mesh.get_aabb()

	# Move the obstacle to the bottom-center of the mesh geometry
	global_transform = Transform3D(
		instance_transform.basis.orthonormalized(), # Unscaled global rotation matrix
		instance_transform * get_bottom_center(local_aabb), # Horizontal midpoint (X and Z), vertical lowest point (Y)
	)

	var mesh_vertices := mesh.get_faces()
	if mesh_vertices.is_empty():
		printerr("%s has no vertices, so %s cannot generate" % [mesh_instance, self])
		return

	# Calculate vertices
	var global_to_obstacle := global_transform.affine_inverse()
	var points_2d := PackedVector2Array()

	for vertex in mesh_vertices:
		points_2d.append(
			Util.vec3to2(
				global_to_obstacle * instance_transform * vertex,
				Util.VECTOR3Y,
			),
		)

	var obstacle_vertices := PackedVector3Array()
	for point in Geometry2D.convex_hull(points_2d):
		obstacle_vertices.append(Util.vec2to3(point, Util.VECTOR3Y))

	if flip_winding_order:
		obstacle_vertices.reverse()

	vertices = obstacle_vertices

	var instance_global_scale: Vector3 = instance_transform.basis.get_scale()
	height = local_aabb.size.y * instance_global_scale.y

	# Radius is half the widest side
	var scaled_size_x: float = local_aabb.size.x * instance_global_scale.x
	var scaled_size_z: float = local_aabb.size.z * instance_global_scale.z
	radius = max(scaled_size_x, scaled_size_z) / 2.0
