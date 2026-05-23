extends EntityGuide3D
class_name NavEntityGuide3D

@export var nav: NavigationAgent3D

func set_target(to: Vector3) -> void:
	target_position = to
	nav.target_position = to

func get_direction() -> Vector3:
	if not has_entity():
		return Vector3.ZERO
	var next: Vector3 = nav.get_next_path_position()
	return entity.global_position.direction_to(next)

func has_entity() -> bool: return is_instance_valid(entity)

func face_target() -> void:
	if not has_entity():
		return
	if not nav.is_target_reachable():
		Util.lerp_look_at_3d(entity, target_position, face_interpolation)
		return
	var next: Vector3 = nav.get_next_path_position()
	next.y = entity.global_position.y
	Util.lerp_look_at_3d(entity, next, face_interpolation)

func get_distance_to_target() -> float:
	return nav.distance_to_target()

func move_forward() -> void:
	if not nav.is_target_reachable():
		return
	entity.move_forward()

func get_annulus_point(inner_radius: float, outer_radius: float) -> Vector3:
	if not has_entity():
		printerr(self, " cannot get annulus point without entity")
		return Vector3.ZERO
	
	var angle := randf() * TAU
	var radius := sqrt(randf_range(inner_radius * inner_radius, outer_radius * outer_radius))
	return entity.global_position + Vector3(cos(angle) * radius, 0.0, sin(angle) * radius)

func get_nearby_navigable_position(inner_radius: float, outer_radius: float, attempts: int = 16) -> Vector3:
	if not has_entity():
		printerr(self, " cannot find navigable position without entity")
		return Vector3.ZERO
	
	var nav_map := nav.get_navigation_map()
	var origin := entity.global_position
	
	# Fail to navigate if no RID
	if not nav_map.is_valid():
		return origin
	
	inner_radius = max(inner_radius, 0.0)
	outer_radius = max(outer_radius, inner_radius)
	attempts = max(attempts, 1)
	
	for i in attempts:
		# Random point in an annulus on the XZ plane
		var nav_point := NavigationServer3D.map_get_closest_point(nav_map, get_annulus_point(inner_radius, outer_radius))
		var distance := nav_point.distance_to(origin)
		if distance >= inner_radius and distance <= outer_radius:
			return nav_point
	
	return entity.global_position
