class_name WedgeTelegraph3D
extends PlanarTelegraph3D

@export_custom(PROPERTY_HINT_NONE, "suffix:m") var radius := 4.0
@export_custom(PROPERTY_HINT_NONE, "suffix:°") var arc_degrees := 90.0
@export var segments := 24


func _build_mesh() -> Mesh:
	var arc := deg_to_rad(arc_degrees)
	return _build_fan(arc, segments, -arc / 2.0)


func get_shape_scale() -> Vector3:
	return Vector3(radius, 1.0, radius)
