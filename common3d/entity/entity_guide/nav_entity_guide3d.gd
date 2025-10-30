extends EntityGuide3D
class_name NavEntityGuide3D

@export var nav: NavigationAgent3D

func get_direction(target: Vector3) -> Vector3:
	if not is_instance_valid(entity):
		return Vector3.ZERO
	
	nav.target_position = target
	
	var next: Vector3 = nav.get_next_path_position()
	if entity.rotatable_axis != null:
		entity.look_at(next)
		entity.global_rotation *= entity.rotatable_axis.as_vector()
	return entity.global_position.direction_to(next)
