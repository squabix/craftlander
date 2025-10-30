extends Node3D
class_name CardinalRayCaster3D

@export_flags_3d_physics var collision_mask: int = 1

func is_colliding() -> bool:
	var space_state = get_world_3d().direct_space_state
	var origin = global_transform.origin
	var directions = [
		Vector3.DOWN,
		Vector3.UP,
		Vector3.LEFT,
		Vector3.RIGHT,
		Vector3.FORWARD,
		Vector3.BACK
	]

	var has_support := false
	for dir in directions:
		var from = origin
		var to = origin + dir * 1.1 # Adjust distance to your grid/block size
		var result = space_state.intersect_ray(
			PhysicsRayQueryParameters3D.create(
				from, to, collision_mask, [self]
			)
		)
		if not result.is_empty():
			has_support = true
			break
	return has_support
