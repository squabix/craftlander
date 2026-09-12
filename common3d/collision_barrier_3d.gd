@tool
class_name CollisionBarrier3D
extends CollisionShape3D

@export var sample: Node3D:
	set(value):
		sample = value
		if is_inside_tree():
			generate()
@export var generate_on_ready := false
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var buffer := 0.05:
	set(value):
		buffer = max(value, 0.0) # Prevent negative buffers
		if is_inside_tree():
			generate()
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var max_sample_height := 3.0:
	set(value):
		max_sample_height = max(value, 0.0)
		if is_inside_tree():
			generate()
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var height := 1000.0:
	set(value):
		height = max(value, 0.0)
		if is_inside_tree():
			generate()
@export var direction := Vector3.UP:
	set(value):
		direction = value
		if is_inside_tree():
			generate()
@export_tool_button("Regenerate", "ArrayMesh") var generate_action := generate


func _ready() -> void:
	if generate_on_ready and not Engine.is_editor_hint():
		generate.call_deferred()


func reset() -> void:
	shape = null


func generate() -> void:
	if sample == null:
		reset()
		return

	var local_vertices := _get_sample_vertices()
	if local_vertices.is_empty():
		Util.node_error("%s has no vertices to sample, so %s cannot generate", sample, self)
		return

	var min_position := Vector3(INF, INF, INF)
	var max_position := Vector3(-INF, -INF, -INF)
	var global_vertices: PackedVector3Array = []

	for vertex in local_vertices:
		var global_vertex := sample.global_transform * vertex
		global_vertices.append(global_vertex)
		min_position = min_position.min(global_vertex)
		max_position = max_position.max(global_vertex)

	var sampled_min := Vector3(INF, INF, INF)
	var sampled_max := Vector3(-INF, -INF, -INF)
	var sampled_vertices := PackedVector3Array()
	for vertex in global_vertices:
		if vertex.y - min_position.y > max_sample_height:
			continue
		sampled_vertices.append(vertex)
		sampled_min = sampled_min.min(vertex)
		sampled_max = sampled_max.max(vertex)

	if sampled_vertices.is_empty():
		Util.node_error("%s has no vertices within max_sample_height, so %s cannot generate", sample, self)
		return

	var global_bottom_center := MeshNavigationObstacle3D.get_bottom_center(sampled_min, sampled_max)

	# Keep upright regardless of the sample's own rotation/tilt
	global_transform = Transform3D(Basis.IDENTITY, global_bottom_center)

	var extrusion := direction.normalized() * height if direction != Vector3.ZERO else Vector3.UP * height

	var points := MeshNavigationObstacle3D.global_to_local_plane(sampled_vertices, global_bottom_center)
	var prism_points := PackedVector3Array()
	for point in Geometry2D.convex_hull(points):
		if buffer > 0.0 and point != Vector2.ZERO:
			point += point.normalized() * buffer

		var base_point := Util.vec2to3(point, Util.VECTOR3Y)
		prism_points.append(base_point)
		prism_points.append(base_point + extrusion)

	var polygon_shape := ConvexPolygonShape3D.new()
	polygon_shape.points = prism_points
	shape = polygon_shape


func _get_sample_vertices() -> PackedVector3Array:
	if sample is MeshInstance3D:
		var mesh := (sample as MeshInstance3D).mesh
		return mesh.get_faces() if mesh != null else PackedVector3Array()

	if sample is CollisionShape3D:
		var collision_shape := (sample as CollisionShape3D).shape
		return collision_shape.get_debug_mesh().get_faces() if collision_shape != null else PackedVector3Array()

	Util.node_error("%s does not know how to sample verticies from %s", self, sample)
	return PackedVector3Array()
