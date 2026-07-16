@tool
class_name MeshNavigationObstacle3D
extends NavigationObstacle3D

@export var mesh_instance: MeshInstance3D:
	set(value):
		if not is_inside_tree():
			return
		mesh_instance = value
		generate()
@export var generate_on_ready := false
@export var flip_winding_order: bool = false:
	set(value):
		if not is_inside_tree():
			return
		flip_winding_order = value
		generate()
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var buffer := 0.05:
	set(value):
		if not is_inside_tree():
			return
		buffer = max(value, 0.0) # Prevent negative buffers
		generate()
@export_tool_button("Regenerate", "ArrayMesh") var generate_action := generate


static func get_bottom_center(min_position: Vector3, max_position: Vector3) -> Vector3:
	return Vector3(
		min_position.x + (max_position.x - min_position.x) / 2.0,
		min_position.y,
		min_position.z + (max_position.z - min_position.z) / 2.0,
	)


func _ready() -> void:
	if generate_on_ready and not Engine.is_editor_hint():
		generate.call_deferred()


func reset() -> void:
	vertices = PackedVector3Array()
	radius = 0.0
	height = 0.0


static func global_to_local_plane(global_vertices: PackedVector3Array, global_bottom_center: Vector3) -> PackedVector2Array:
	var points := PackedVector2Array()
	for global_vertex in global_vertices:
		points.append(Util.vec3to2(global_vertex - global_bottom_center, Util.VECTOR3Y))
	return points


func generate() -> void:
	if mesh_instance == null or mesh_instance.mesh == null:
		reset()
		return

	var mesh_vertices := mesh_instance.mesh.get_faces()
	if mesh_vertices.is_empty():
		printerr("%s has no vertices, so %s cannot generate" % [mesh_instance, self])
		return

	var min_pos := Vector3(INF, INF, INF)
	var max_pos := Vector3(-INF, -INF, -INF)
	var global_vertices: PackedVector3Array = []

	for vertex in mesh_vertices:
		var global_vertex := mesh_instance.global_transform * vertex
		global_vertices.append(global_vertex)

		min_pos.x = min(min_pos.x, global_vertex.x)
		min_pos.y = min(min_pos.y, global_vertex.y)
		min_pos.z = min(min_pos.z, global_vertex.z)

		max_pos.x = max(max_pos.x, global_vertex.x)
		max_pos.y = max(max_pos.y, global_vertex.y)
		max_pos.z = max(max_pos.z, global_vertex.z)

	var global_bottom_center := get_bottom_center(min_pos, max_pos)

	# Keep obstacle completely upright relative to world floor to ensure its local XZ plane aligns with navigation map plane
	global_transform = Transform3D(Basis.IDENTITY, global_bottom_center)

	var max_radius_sq := 0.0
	var obstacle_vertices := PackedVector3Array()
	
	var points := global_to_local_plane(global_vertices, global_bottom_center)
	for point in Geometry2D.convex_hull(points):
		# Track the maximum horizontal distance from the center (0,0) before buffer
		var distance_sq := point.length_squared()
		if distance_sq > max_radius_sq:
			max_radius_sq = distance_sq

		# Push the vertex outward from the center (0,0) along its directional vector
		if buffer > 0.0 and point != Vector2.ZERO:
			point += point.normalized() * buffer

		obstacle_vertices.append(Util.vec2to3(point, Util.VECTOR3Y))

	if flip_winding_order:
		obstacle_vertices.reverse()

	vertices = obstacle_vertices

	height = max_pos.y - min_pos.y
	radius = sqrt(max_radius_sq) + buffer
