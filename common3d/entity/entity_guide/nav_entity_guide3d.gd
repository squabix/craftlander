class_name NavEntityGuide3D
extends EntityGuide3D

const SAFE_VELOCITY_MIN_LENGTH_SQ := 0.1
const DIRECTION_MIN_LENGTH_SQ := 0.05

@export var nav: NavigationAgent3D
@export_range(0.0, 1.0) var rotation_ratio := 0.25

@export_group("Move Directly", "move_directly")
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var move_directly_range := 3.6

@export_subgroup("Ray Casting", "move_directly_ray")
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var move_directly_ray_offset := Vector3.UP * 0.5
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var move_directly_ray_intersect_radius := 0.6

var safe_velocity := Vector3.ZERO # Calculated by the NavigationServer


func _ready() -> void:
	nav.avoidance_enabled = true
	nav.velocity_computed.connect(update_computed_velocity) # Update safe velocity whenever computed


func update_computed_velocity(to: Vector3) -> void:
	safe_velocity = to


func set_target(to: Vector3) -> void:
	if target_position.is_equal_approx(to):
		return

	target_position = to
	nav.target_position = to


func get_direction() -> Vector3:
	return (
			Vector3.ZERO if not has_entity() # No direction without entity
			else entity.global_position.direction_to(target_position) if has_direct_shot() # Direct shot direction
			else safe_velocity.normalized() if safe_velocity.length_squared() > SAFE_VELOCITY_MIN_LENGTH_SQ # Safe velocity if long enough
			else entity.global_position.direction_to(nav.get_next_path_position()) # Direction to next path position
	)


func has_entity() -> bool:
	return is_instance_valid(entity)


func face_target() -> void:
	if not has_entity():
		return

	var face_direction := get_face_direction()
	if face_direction.length_squared() < DIRECTION_MIN_LENGTH_SQ:
		return

	Util.lerp_look_at_3d(
		entity,
		entity.global_position + face_direction,
		face_interpolation,
	)


func get_face_direction() -> Vector3:
	var target_direction := entity.global_position.direction_to(
		target_position if has_direct_shot() else nav.get_next_path_position() if nav.is_target_reachable()
		else target_position,
	)

	var move_direction := get_direction()
	var nonzero_move_direction := move_direction.length_squared() > DIRECTION_MIN_LENGTH_SQ

	var blended_direction := (
			target_direction.lerp(move_direction, rotation_ratio).normalized() if nonzero_move_direction
			else target_direction
	)
	return (blended_direction * Vector3(Util.VECTOR3XZ)).normalized()


func get_distance_to_target() -> float:
	return nav.distance_to_target()


func get_nav_velocity() -> Vector3:
	if not has_entity():
		push_error("%s has no nav velocity without entity" % self)
		return Vector3.ZERO
	var speed := entity.move_mode.max_speed.x
	var direction := entity.global_position.direction_to(
		target_position if has_direct_shot() else nav.get_next_path_position(),
	)
	return speed * direction


func move_forward() -> void:
	if not has_entity():
		push_error("%s cannot move forward without entity" % self)
		return

	nav.velocity = get_nav_velocity()

	var move_direction := get_direction()
	if move_direction.length_squared() < DIRECTION_MIN_LENGTH_SQ:
		return

	var rotated_move_direction := entity.global_transform.basis.inverse() * move_direction
	entity.move_planar(Util.vec3to2(rotated_move_direction, Util.VECTOR3Y).normalized())


func get_annulus_point(inner_radius: float, outer_radius: float) -> Vector3:
	if not has_entity():
		push_error("%s cannot get annulus point without entity" % self)
		return Vector3.ZERO

	var angle := randf() * TAU
	var radius := sqrt(randf_range(inner_radius * inner_radius, outer_radius * outer_radius))
	return entity.global_position + Vector3(cos(angle) * radius, 0.0, sin(angle) * radius)


func get_nearby_navigable_position(inner_radius: float, outer_radius: float, attempts: int = 16) -> Vector3:
	if not has_entity():
		push_error("%s cannot find navigable position without entity" % self)
		return Vector3.ZERO

	var nav_map := nav.get_navigation_map()
	var origin := entity.global_position

	if not nav_map.is_valid():
		return origin

	# Clamp radii
	inner_radius = max(inner_radius, 0.0)
	outer_radius = max(outer_radius, inner_radius)

	attempts = max(attempts, 1)

	# Square radii
	var inner_radius_sq := inner_radius * inner_radius
	var outer_radius_sq := outer_radius * outer_radius

	for i in attempts:
		var nav_point := NavigationServer3D.map_get_closest_point(nav_map, get_annulus_point(inner_radius, outer_radius))
		var distance_sq := nav_point.distance_squared_to(origin)

		if distance_sq >= inner_radius_sq and distance_sq <= outer_radius_sq:
			return nav_point

	return origin


func within_move_directly_range() -> bool:
	return (
			has_entity()
			and move_directly_range > 0.0
			and entity.global_position.distance_squared_to(target_position) < move_directly_range * move_directly_range
	)


func has_direct_shot() -> bool:
	if not within_move_directly_range():
		return false # Fail if not within direct walk range

	var start := entity.global_position + move_directly_ray_offset
	var end := target_position + move_directly_ray_offset

	var result := _get_move_directly_ray_result(start, end)
	if result.is_empty():
		return true

	return _is_within_intersect_radius(result.position, end)


func _on_velocity_computed(computed_velocity: Vector3) -> void:
	safe_velocity = computed_velocity


func _is_within_intersect_radius(position: Vector3, end: Vector3) -> bool:
	var distance_sq := (position as Vector3).distance_squared_to(end)
	var radius_sq := move_directly_ray_intersect_radius * move_directly_ray_intersect_radius
	return distance_sq <= radius_sq


func _get_move_directly_ray_result(start: Vector3, end: Vector3) -> Dictionary:
	if not has_entity():
		push_error("%s cannot get move directly ray result without entity" % self)
		return { }
	if start == end:
		push_error("%s cannot get move directly ray result between two equal points: %s and %s" % [self, start, end])
		return { }
	var query := PhysicsRayQueryParameters3D.create(start, end, 0xFFFFFFFF, [entity.get_rid()])
	return entity.get_world_3d().direct_space_state.intersect_ray(query)
