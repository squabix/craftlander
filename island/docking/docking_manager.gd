class_name DockingManager
extends Node3D

const DOCK_ELEVATION_OFFSET := 0.65
const DEFAULT_DOCK_PLACE_RAY_LENGTH := 400.0
const DOCK_EXPOSED_LENGTH := 11.5
const SEPARATION_MAX_ATTEMPTS := 200

@export var dock: Node3D

@export_group("Boat", "boat")
@export var boat_adder: BoatAdder
@export var boat_dock_point: Node3D
@export var boat_auto_add := true

@export_group("Dock Placement Rays", "dock_place_ray")
@export var dock_place_ray_container: Node3D
@export var dock_place_ray_null_point := Vector3.ZERO

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


func set_dock_position(to: Vector3) -> void:
	dock.global_position = to + Vector3.UP * DOCK_ELEVATION_OFFSET
	dock.global_position = dock.global_position.move_toward(global_position, -DOCK_EXPOSED_LENGTH)


func are_dock_places_rays_colliding(at_point: Vector3) -> bool:
	var length := dock_place_ray_container.global_position.distance_to(at_point)

	for ray in dock_place_ray_container.get_children():
		ray.target_position = Vector3.FORWARD * length
		ray.force_raycast_update()
		if not ray.is_colliding():
			return false

	return true


func place_dock() -> void:
	var found_placement := false

	var placement_point: Vector3
	var attempts := 0

	while not found_placement:
		attempts += 1
		extend_dock_place_rays()
		rotation_degrees.y = randf_range(
			rotation_degrees_from + rotation_degrees_offset,
			rotation_degrees_to - rotation_degrees_offset
		)
		if attempts == SEPARATION_MAX_ATTEMPTS and not separation_avoid_managers.is_empty():
			push_warning("%s could not keep %s degrees away from its avoided docks; ignoring separation" % [name, separation_min_degrees])
		if attempts < SEPARATION_MAX_ATTEMPTS and not _is_separated_from_avoided():
			continue

		placement_point = get_first_ray_collision_point()
		if placement_point == dock_place_ray_null_point:
			continue

		found_placement = are_dock_places_rays_colliding(placement_point)

	set_dock_position(placement_point)


func _is_separated_from_avoided() -> bool:
	for other in separation_avoid_managers:
		if not is_instance_valid(other):
			continue
		var difference := angle_difference(deg_to_rad(rotation_degrees.y), deg_to_rad(other.rotation_degrees.y))
		if absf(difference) < deg_to_rad(separation_min_degrees):
			return false
	return true
