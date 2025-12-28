extends RayCast3D
class_name PointerRayCast3D

@export var offset := 0.0

func get_end() -> Vector3:
	return global_position + global_transform.basis * target_position

func _process(_delta: float) -> void:
	var collision_point := get_collision_point() if is_colliding() else get_end()
	for child in get_children():
		child.global_position = collision_point.move_toward(global_position, offset)
