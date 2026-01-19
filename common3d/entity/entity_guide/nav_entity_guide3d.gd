extends EntityGuide3D
class_name NavEntityGuide3D

@export var nav: NavigationAgent3D

func set_target(to: Vector3) -> void:
	target_position = to
	nav.target_position = to

func get_direction() -> Vector3:
	if not is_instance_valid(entity):
		return Vector3.ZERO
	var next: Vector3 = nav.get_next_path_position()
	entity.look_at(next)
	return entity.global_position.direction_to(next)

func face_target() -> void:
	if not is_instance_valid(entity):
		return
	var next: Vector3 = nav.get_next_path_position()
	entity.look_at(next)
