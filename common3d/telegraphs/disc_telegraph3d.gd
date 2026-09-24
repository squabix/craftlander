class_name DiscTelegraph3D
extends PlanarTelegraph3D

@export_custom(PROPERTY_HINT_NONE, "suffix:m") var radius := 4.0
@export var segments := 40


func _build_mesh() -> Mesh:
	return _build_fan(TAU, segments, 0.0)


func get_shape_scale() -> Vector3:
	return Vector3(radius, 1.0, radius)
