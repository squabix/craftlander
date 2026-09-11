@tool
class_name MeshBarrier3D
extends CollisionShape3D

@export var mesh_instance: MeshInstance3D:
	set(value):
		mesh_instance = value
		if is_inside_tree():
			generate()
@export var generate_on_ready := false
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var buffer := 0.05:
	set(value):
		buffer = max(value, 0.0)
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
@export_tool_button("Generate", "ArrayMesh") var generate_action := generate


func _ready() -> void:
	if generate_on_ready and not Engine.is_editor_hint():
		generate.call_deferred()


func reset() -> void:
	shape = null


func generate() -> void:
	if mesh_instance == null or mesh_instance.mesh == null:
		reset()
		return

	var mesh_vertices := mesh_instance.mesh.get_faces()
	if mesh_vertices.is_empty():
		Util.node_error("%s has no vertices, so %s cannot generate", mesh_instance, self)
		return

	var min_position := Vector3(INF, INF, INF)
	var max_position := Vector3(-INF, -INF, -INF)
	var global_vertices: PackedVector3Array = []

	for vertex in mesh_vertices:
		var global_vertex := mesh_instance.global_transform * vertex
		global_vertices.append(global_vertex)
		min_position = min_position.min(global_vertex)
		max_position = max_position.max(global_vertex)

	var global_bottom_center := MeshNavigationObstacle3D.get_bottom_center(min_position, max_position)

	# Keep upright regardless of the mesh instance's rotation/tilt
	global_transform = Transform3D(Basis.IDENTITY, global_bottom_center)

	var extrusion := direction.normalized() * height if direction != Vector3.ZERO else Vector3.UP * height

	var points := MeshNavigationObstacle3D.global_to_local_plane(global_vertices, global_bottom_center)
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
