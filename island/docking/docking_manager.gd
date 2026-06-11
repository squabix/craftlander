extends Node3D

const DOCK_ELEVATION_OFFSET := 0.65
const DEFAULT_DOCK_PLACE_RAY_LENGTH := 400.0
const DOCK_EXPOSED_LENGTH := 6.0

@export var dock_place_ray_container: Node3D
@export var boat_dock_point: Node3D
@export var dock: Node3D
@export var boat: Boat

func _ready() -> void:
	await get_tree().process_frame
	place_dock()
	boat.dock_position = boat_dock_point.global_position
	boat.look_at(boat.dock_position)

func extend_dock_place_rays() -> void:
	for ray in dock_place_ray_container.get_children():
		ray.target_position = Vector3.FORWARD * DEFAULT_DOCK_PLACE_RAY_LENGTH

func get_first_ray_collision_point() -> Vector3:
	var first_ray = dock_place_ray_container.get_child(0) as RayCast3D
	first_ray.force_raycast_update()
	
	if not first_ray.is_colliding():
		return Vector3.ZERO
		
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
	
	while not found_placement:
		extend_dock_place_rays()
		rotation_degrees.y = randf_range(0.0, 360.0)
		
		placement_point = get_first_ray_collision_point()
		
		if placement_point == Vector3.ZERO:
			continue
		
		found_placement = are_dock_places_rays_colliding(placement_point)
	
	set_dock_position(placement_point)
