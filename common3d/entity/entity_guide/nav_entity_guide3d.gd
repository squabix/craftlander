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
	return entity.global_position.direction_to(next)

func face_target() -> void:
	if not is_instance_valid(entity):
		return
	if not nav.is_target_reachable():
		Util.lerp_look_at_3d(entity, target_position, face_interpolation)
		return
	var next: Vector3 = nav.get_next_path_position()
	Util.lerp_look_at_3d(entity, next, face_interpolation)

func get_distance_to_target() -> float:
	return nav.distance_to_target()

func move_forward() -> void:
	if not nav.is_target_reachable():
		return
	entity.move_forward()

func get_nearby_navigable_position(
	inner_radius: float,
	outer_radius: float,
	attempts: int = 16
) -> Vector3:
	var nav_map := nav.get_navigation_map()
	if nav_map == RID():
		return entity.global_position
	
	inner_radius = max(inner_radius, 0.0)
	outer_radius = max(outer_radius, inner_radius)
	
	for i in attempts:
		# Random point in an annulus on the XZ plane
		var angle := randf() * TAU
		var dist: float = lerp(inner_radius, outer_radius, randf())
		var candidate := entity.global_position + Vector3(cos(angle) * dist, 0.0, sin(angle) * dist)
	
		var nav_point := NavigationServer3D.map_get_closest_point(nav_map, candidate)
	
		var d := nav_point.distance_to(entity.global_position)
		if d >= inner_radius and d <= outer_radius:
			return nav_point
	
	# Fallback: closest point to the middle of the ring
	var fallback_pos := entity.global_position + Vector3(outer_radius, 0.0, 0.0)
	return NavigationServer3D.map_get_closest_point(nav_map, fallback_pos)
