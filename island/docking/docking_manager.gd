class_name DockingManager
extends Node3D

const DOCK_ELEVATION_OFFSET := 0.65
const DEFAULT_DOCK_PLACE_RAY_LENGTH := 400.0
const DOCK_EXPOSED_LENGTH := 11.5
const SEPARATION_MAX_ATTEMPTS := 200
const ROTATION_RANGE_MAX_ATTEMPTS := 1000
const PLACEMENT_MAX_ATTEMPTS := 2000
const FULL_TURN_DEGREES := 360.0
const LAND_PROBE_HEIGHT := 300.0 # m

@export var dock: Node3D

@export_group("Boat", "boat")
@export var boat_adder: BoatAdder
@export var boat_dock_point: Node3D
@export var boat_auto_add := true

@export_group("Dock Placement Rays", "dock_place_ray")
@export var dock_place_ray_container: Node3D
@export var dock_place_ray_null_point := Vector3.ZERO

@export_group("Boat Clearance", "boat_clearance")
@export_flags_3d_physics var boat_clearance_mask := 64
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var boat_clearance_size := Vector3(6.0, 3.0, 7.0)
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var boat_clearance_center_offset := 2.8

@export_group("Rotation", "rotation_degrees")
@export_range(0.0, 360.0, 0.001, "suffix:°") var rotation_degrees_from := 0.0
@export_range(0.0, 360.0, 0.001, "suffix:°") var rotation_degrees_to := 360.0
@export_custom(PROPERTY_HINT_NONE, "suffix:°") var rotation_degrees_offset := 0.0

@export_group("Separation", "separation")
@export var separation_avoid_managers: Array[DockingManager]
@export_range(0.0, 180.0, 0.001, "suffix:°") var separation_min_degrees := 35.0

var boat: Boat


func initialize() -> void:
	place_dock()
	if is_instance_valid(boat_adder) and boat_auto_add:
		add_boat()


func add_boat() -> void:
	if not is_instance_valid(boat_adder):
		Util.node_error("%s cannot add boat with invalid boat adder (%s)", self, boat_adder)
		return
	boat_adder.dock_position = boat_dock_point.global_position
	boat = boat_adder.spawn()


func extend_dock_place_rays() -> void:
	for ray in dock_place_ray_container.get_children():
		ray.target_position = Vector3.FORWARD * DEFAULT_DOCK_PLACE_RAY_LENGTH


func get_first_ray_collision_point() -> Vector3:
	var first_ray = dock_place_ray_container.get_child(0) as RayCast3D
	first_ray.force_raycast_update()

	if not first_ray.is_colliding():
		return dock_place_ray_null_point

	return first_ray.get_collision_point()


func get_dock_position_for(placement_point: Vector3) -> Vector3:
	var raised := placement_point + Vector3.UP * DOCK_ELEVATION_OFFSET
	return raised.move_toward(global_position, -DOCK_EXPOSED_LENGTH)


func get_boat_dock_point_for(placement_point: Vector3) -> Vector3:
	return get_dock_position_for(placement_point) + boat_dock_point.global_position - dock.global_position


func get_boat_route_start() -> Vector3:
	if is_instance_valid(boat_adder):
		return boat_adder.global_position
	return dock_place_ray_container.global_position


func set_dock_position(to: Vector3) -> void:
	dock.global_position = get_dock_position_for(to)


func are_dock_places_rays_colliding(at_point: Vector3) -> bool:
	var length := dock_place_ray_container.global_position.distance_to(at_point)

	for ray in dock_place_ray_container.get_children():
		ray.target_position = Vector3.FORWARD * length
		ray.force_raycast_update()
		if not ray.is_colliding():
			return false

	return true


func is_land_at(point: Vector3) -> bool:
	var probe := PhysicsRayQueryParameters3D.create(
		Vector3(point.x, LAND_PROBE_HEIGHT, point.z),
		Vector3(point.x, -LAND_PROBE_HEIGHT, point.z),
		boat_clearance_mask
	)
	var hit := get_world_3d().direct_space_state.intersect_ray(probe)
	return not hit.is_empty() and hit.position.y > dock_place_ray_container.global_position.y


func is_boat_route_clear(placement_point: Vector3) -> bool:
	if not is_instance_valid(boat_dock_point):
		return true

	var water_height := dock_place_ray_container.global_position.y
	var start := get_boat_route_start()
	var end := get_boat_dock_point_for(placement_point)
	start.y = water_height
	end.y = water_height

	var route_basis := Basis.looking_at(end - start)
	var body_offset := route_basis.z * boat_clearance_center_offset
	var box_lift := Vector3.UP * boat_clearance_size.y * 0.5

	var clearance_box := BoxShape3D.new()
	clearance_box.size = boat_clearance_size

	var sweep := PhysicsShapeQueryParameters3D.new()
	sweep.shape = clearance_box
	sweep.collision_mask = boat_clearance_mask
	sweep.transform = Transform3D(route_basis, start + body_offset + box_lift)
	sweep.motion = end - start

	var safe_fractions := get_world_3d().direct_space_state.cast_motion(sweep)
	if safe_fractions.size() < 2 or safe_fractions[0] < 1.0:
		return false

	return not is_land_at(end) and not is_land_at(end + body_offset)


func place_dock() -> void:
	var found_placement := false

	var placement_point: Vector3
	var fallback_point: Vector3
	var fallback_rotation_degrees := 0.0
	var has_fallback := false
	var attempts := 0

	while not found_placement:
		attempts += 1
		if attempts > PLACEMENT_MAX_ATTEMPTS:
			if not has_fallback:
				Util.node_error("%s could not find any dock placement after %s attempts", self, PLACEMENT_MAX_ATTEMPTS)
				return
			Util.node_error("%s found no dock placement with a clear boat route after %s attempts; using an unchecked one", self, PLACEMENT_MAX_ATTEMPTS)
			rotation_degrees.y = fallback_rotation_degrees
			set_dock_position(fallback_point)
			return

		extend_dock_place_rays()
		rotation_degrees.y = get_random_rotation_degrees(attempts < ROTATION_RANGE_MAX_ATTEMPTS)
		if attempts == SEPARATION_MAX_ATTEMPTS and not separation_avoid_managers.is_empty():
			push_warning("%s could not keep %s degrees away from its avoided docks; ignoring separation" % [name, separation_min_degrees])
		if attempts < SEPARATION_MAX_ATTEMPTS and not _is_separated_from_avoided():
			continue

		placement_point = get_first_ray_collision_point()
		if placement_point == dock_place_ray_null_point:
			continue

		if not are_dock_places_rays_colliding(placement_point):
			continue

		has_fallback = true
		fallback_point = placement_point
		fallback_rotation_degrees = rotation_degrees.y
		found_placement = is_boat_route_clear(placement_point)

	set_dock_position(placement_point)


func get_random_rotation_degrees(within_range: bool) -> float:
	if not within_range:
		return randf_range(0.0, FULL_TURN_DEGREES)
	return randf_range(
		rotation_degrees_from + rotation_degrees_offset,
		rotation_degrees_to - rotation_degrees_offset
	)


func _is_separated_from_avoided() -> bool:
	for other in separation_avoid_managers:
		if not is_instance_valid(other):
			continue
		var difference := angle_difference(deg_to_rad(rotation_degrees.y), deg_to_rad(other.rotation_degrees.y))
		if absf(difference) < deg_to_rad(separation_min_degrees):
			return false
	return true
