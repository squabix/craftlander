class_name LinearEntityGuide3D
extends EntityGuide3D


func face_target() -> void:
	var face_direction := get_offset_to_target()
	if face_direction.length_squared() < 0.0001:
		return
	face_direction = face_direction.normalized()
	Util.lerp_look_at_3d(
		entity,
		entity.global_position + face_direction,
		face_interpolation,
	)


func get_distance_to_target() -> float:
	if not is_instance_valid(entity):
		return INF
	return get_offset_to_target().length()


func get_direction() -> Vector3:
	if not is_instance_valid(entity):
		return Vector3.ZERO

	entity.look_at(target_position)
	entity.global_rotation *= entity.rotatable_axis.as_vector()
	var direction: Vector3 = entity.global_position.direction_to(target_position)
	return direction


func get_offset_to_target() -> Vector3:
	var offset := target_position - entity.global_position
	if ignore_y_distance:
		offset.y = 0.0
	return offset
