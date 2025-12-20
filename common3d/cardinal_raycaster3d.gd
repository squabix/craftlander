extends Node3D
class_name CardinalRayCaster3D

@export_flags_3d_physics var collision_mask := 1
@export var ray_length: float = 1.0

func get_colliding_directions() -> PackedVector3Array:
	var space_state := get_world_3d().direct_space_state
	var origin := global_transform.origin
	var directions: PackedVector3Array = [
		Vector3.DOWN,
		Vector3.UP,
		Vector3.LEFT,
		Vector3.RIGHT,
		Vector3.FORWARD,
		Vector3.BACK
	]
	
	# Remove directions that don't intersect emitted rays
	for dir in directions:
		var from := origin
		var to := origin + dir * ray_length
		var result := space_state.intersect_ray(
			PhysicsRayQueryParameters3D.create(
				from, to, collision_mask, [self]
			)
		)
		if result.is_empty():
			directions.erase(dir)
	return directions
