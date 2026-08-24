class_name NavEntityGuide3D
extends EntityGuide3D

signal nav_ready

const SAFE_VELOCITY_MIN_LENGTH_SQ := 0.1
const DIRECTION_MIN_LENGTH_SQ := 0.05

@export var nav: NavigationAgent3D
@export_range(0.0, 1.0) var rotation_ratio := 0.25

@export_group("Off Navmesh Settings")
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var off_navmesh_threshold: float = 0.3
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var navmesh_ingress_depth: float = 0.4
@export var ignore_y_distance := true

@export_group("Move Directly", "move_directly")
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var move_directly_range := 3.6

@export_subgroup("Ray Casting", "move_directly_ray")
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var move_directly_ray_offset := Vector3.UP * 0.5
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var move_directly_ray_intersect_radius := 0.6

var safe_velocity := Vector3.ZERO # Calculated by the NavigationServer
var _is_nav_ready := false


func _ready() -> void:
	nav.avoidance_enabled = true
	nav.velocity_computed.connect(update_computed_velocity) # Update safe velocity whenever computed
	
	_setup_nav_map.call_deferred()


func _setup_nav_map() -> void:
	if not is_inside_tree():
		return
	
	# Force explicit world navigation map fallback if agent map isn't assigned yet
	if not nav.get_navigation_map().is_valid() and has_entity() and entity.get_world_3d():
		nav.set_navigation_map(entity.get_world_3d().get_navigation_map())

	await get_tree().physics_frame
	_is_nav_ready = true

	# Re-apply target position once map server is fully synced
	if target_position != Vector3.ZERO:
		nav.target_position = target_position
	
	nav_ready.emit()


func update_computed_velocity(to: Vector3) -> void:
	safe_velocity = to


func set_target(to: Vector3) -> void:
	if target_position.is_equal_approx(to):
		return

	target_position = to

	if not is_instance_valid(nav):
		return
	nav.target_position = to


func get_nav_map() -> RID:
	if is_instance_valid(nav):
		var map := nav.get_navigation_map()
		if map.is_valid():
			return map

	if has_entity() and entity.get_world_3d():
		return entity.get_world_3d().get_navigation_map()

	return RID()


func get_closest_navmesh_point(include_ingress: bool = true) -> Vector3:
	if not has_entity():
		return Vector3.ZERO

	var nav_map := get_nav_map()
	if not nav_map.is_valid():
		return entity.global_position

	var closest := NavigationServer3D.map_get_closest_point(nav_map, entity.global_position)

	# Push target inside the navmesh toward target_position
	if not include_ingress or navmesh_ingress_depth <= 0.0:
		return closest
	
	var to_target := (target_position - entity.global_position)
	if ignore_y_distance:
		to_target.y = 0.0
	if to_target.length_squared() > 0.001:
		closest += to_target.normalized() * navmesh_ingress_depth

	return closest


func is_outside_navmesh() -> bool:
	if not has_entity():
		return false

	var nav_map := get_nav_map()
	if not nav_map.is_valid():
		return false

	var closest_point := NavigationServer3D.map_get_closest_point(nav_map, entity.global_position)

	var distance := (
		Util.vec3to2(entity.global_position - closest_point, Util.VECTOR3Y).length() if ignore_y_distance
		else entity.global_position.distance_to(closest_point)
	)

	return distance > off_navmesh_threshold


func _get_horizontal_direction_to(from: Vector3, to: Vector3) -> Vector3:
	var direction := to - from
	if ignore_y_distance:
		direction.y = 0.0
	return direction.normalized()


func get_direction() -> Vector3:
	if not has_entity():
		return Vector3.ZERO
	if has_direct_shot():
		return _get_horizontal_direction_to(entity.global_position, target_position)
	if is_outside_navmesh():
		return _get_horizontal_direction_to(entity.global_position, get_closest_navmesh_point(true))
	if safe_velocity.length_squared() > SAFE_VELOCITY_MIN_LENGTH_SQ:
		return safe_velocity.normalized()
	if not _is_nav_ready:
		return _get_horizontal_direction_to(entity.global_position, get_closest_navmesh_point(true))
	return _get_horizontal_direction_to(entity.global_position, nav.get_next_path_position())


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


func get_target_direction() -> Vector3:
	var move_direction := get_direction()
	if has_direct_shot():
		return _get_horizontal_direction_to(entity.global_position, target_position)
	elif is_outside_navmesh():
		return move_direction # Face steering while off-mesh
	elif nav.is_target_reachable():
		return _get_horizontal_direction_to(entity.global_position, nav.get_next_path_position())
	return _get_horizontal_direction_to(entity.global_position, target_position)


func get_face_direction() -> Vector3:
	var move_direction := get_direction()

	var blended_direction := get_target_direction()
	if move_direction.length_squared() > DIRECTION_MIN_LENGTH_SQ:
		blended_direction = blended_direction.lerp(move_direction, rotation_ratio).normalized()
	
	return (blended_direction * Vector3(Util.VECTOR3XZ)).normalized()


func get_distance_to_target() -> float:
	return nav.distance_to_target()


func get_nav_velocity() -> Vector3:
	if not has_entity():
		Util.node_error("%s has no nav velocity without entity", self)
		return Vector3.ZERO
	var speed := entity.move_mode.max_speed.x

	var direction := (
		_get_horizontal_direction_to(entity.global_position, target_position) if has_direct_shot()
		else _get_horizontal_direction_to(entity.global_position, get_closest_navmesh_point(true)) if is_outside_navmesh()
		else _get_horizontal_direction_to(entity.global_position, nav.get_next_path_position())
	)
	return speed * direction


func move_forward() -> void:
	if not has_entity():
		Util.node_error("%s cannot move forward without entity", self)
		return

	nav.velocity = get_nav_velocity()

	var move_direction := get_direction()
	if move_direction.length_squared() < DIRECTION_MIN_LENGTH_SQ:
		return

	var rotated_move_direction := entity.global_transform.basis.inverse() * move_direction
	entity.move_planar(Util.vec3to2(rotated_move_direction, Util.VECTOR3Y).normalized())


func get_annulus_point(inner_radius: float, outer_radius: float) -> Vector3:
	if not has_entity():
		Util.node_error("%s cannot get annulus point without entity", self)
		return Vector3.ZERO

	var angle := randf() * TAU
	var radius := sqrt(randf_range(inner_radius * inner_radius, outer_radius * outer_radius))
	return entity.global_position + Vector3(cos(angle) * radius, 0.0, sin(angle) * radius)


func get_nearby_navigable_position(inner_radius: float, outer_radius: float, attempts: int = 16) -> Vector3:
	if not has_entity():
		Util.node_error("%s cannot find navigable position without entity", self)
		return Vector3.ZERO

	var nav_map := get_nav_map()
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
		Util.node_error("%s cannot get move directly ray result without entity", self)
		return { }
	if start == end:
		Util.node_error("%s cannot get move directly ray result between two equal points: %s and %s", self, start, end)
		return { }
	var query := PhysicsRayQueryParameters3D.create(start, end, 0xFFFFFFFF, [entity.get_rid()])
	return entity.get_world_3d().direct_space_state.intersect_ray(query)
