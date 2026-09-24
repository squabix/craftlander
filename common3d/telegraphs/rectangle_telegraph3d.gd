class_name RectangleTelegraph3D
extends PlanarTelegraph3D

const CORNERS: Array[Vector3] = [
	Vector3(-0.5, 0.0, 0.0),
	Vector3(0.5, 0.0, 0.0),
	Vector3(0.5, 0.0, -1.0),
	Vector3(-0.5, 0.0, -1.0),
]

@export_custom(PROPERTY_HINT_NONE, "suffix:m") var size := Vector2(2.0, 10.0)


func get_shape_scale() -> Vector3:
	return Vector3(size.x, 1.0, size.y)


func get_fill_scale_start() -> Vector3:
	return Vector3(1.0, 1.0, fill_start_scale_amount)


func _build_mesh() -> Mesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for index in [0, 1, 2, 0, 2, 3]:
		tool.add_vertex(CORNERS[index])
	return tool.commit()
