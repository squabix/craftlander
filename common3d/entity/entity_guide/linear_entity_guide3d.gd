class_name LinearEntityGuide3D
extends EntityGuide3D


func face_target() -> void:
	var face_direction := entity.global_position.direction_to(target_position)
	Util.lerp_look_at_3d(
		entity,
		entity.global_position + face_direction,
		face_interpolation,
	)


func get_distance_to_target() -> float:
	if not is_instance_valid(entity):
		return INF
	return entity.global_position.distance_to(target_position)


func get_direction() -> Vector3:
	if not is_instance_valid(entity):
		return Vector3.ZERO

	entity.look_at(target_position)
	entity.global_rotation *= entity.rotatable_axis.as_vector()
	var direction: Vector3 = entity.global_position.direction_to(target_position)
	return direction
