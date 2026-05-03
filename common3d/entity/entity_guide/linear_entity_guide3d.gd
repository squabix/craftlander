extends EntityGuide3D
class_name LinearEntityGuide3D

func get_direction() -> Vector3:
	if not is_instance_valid(entity):
		return Vector3.ZERO
	
	entity.look_at(target_position)
	entity.global_rotation *= entity.rotatable_axis.as_vector()
	var direction: Vector3 = entity.global_position.direction_to(target_position)
	return direction
