extends Node3D

const DOCK_ELEVATION_OFFSET := 0.65
const DEFAULT_DOCK_PLACE_RAY_LENGTH := 400.0
const DOCK_EXPOSED_LENGTH := 6.0

@onready var dock_place_ray_container: Node3D = $DockPlaceRayContainer
@onready var dock: Node3D = $Dock
@onready var boat: Boat = $Boat

func _ready() -> void:
	await get_tree().process_frame
	place_dock()
	boat.dock_position = $Dock/BoatDockPoint.global_position

func place_dock() -> void:
	var found_placement := false
	while not found_placement:
		rotation_degrees.y = randf_range(0.0, 360.0)
		found_placement = true
		for ray in dock_place_ray_container.get_children():
			ray.target_position = Vector3.FORWARD * DEFAULT_DOCK_PLACE_RAY_LENGTH
		
		var first_point := (dock_place_ray_container.get_child(0) as RayCast3D).get_collision_point()
		var first_length := dock_place_ray_container.global_position.distance_to(first_point) - 400.0
		
		for ray in dock_place_ray_container.get_children():
			ray.target_position = Vector3.FORWARD * first_length
			ray.force_raycast_update()
			if not ray.is_colliding():
				found_placement = false
				break
	
	dock.global_position = dock_place_ray_container.get_child(0).get_collision_point()
	dock.global_position += Vector3.UP * DOCK_ELEVATION_OFFSET
	dock.global_position = dock.global_position.move_toward(global_position, -DOCK_EXPOSED_LENGTH)
