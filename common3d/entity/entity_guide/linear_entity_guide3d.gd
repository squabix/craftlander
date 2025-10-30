extends EntityGuide3D
class_name LinearEntityGuide3D

func get_direction(target: Vector3) -> Vector3:
	if not is_instance_valid(entity):
		return Vector3.ZERO
	
	entity.look_at(target)
	entity.global_rotation *= entity.rotatable_axis.as_vector()
	var direction: Vector3 = entity.global_position.direction_to(target)
	return direction
