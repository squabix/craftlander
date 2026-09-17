class_name IceStaffWeapon
extends ProjectileWeapon

@export_group("Aiming")
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var spawn_height_above_target := 10.0
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var max_aim_distance := 60.0
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var max_ground_search_distance := 100.0
@export_flags_3d_physics var aim_collision_mask := 5


func start_use() -> bool:
	if spawner == null:
		return true

	var target_position: Variant = get_target_position()
	if target_position == null:
		return true

	spawner.global_position = (target_position as Vector3) + Vector3.UP * spawn_height_above_target
	spawner.spawn()
	return true


# Aims from the wielder's camera. A hit (enemy or ground) spawns above that point;
# aiming into empty air instead casts a second ray straight down from the aim ray's
# end to find the ground below and spawns above that.
func get_target_position() -> Variant:
	var root3d := root as Node3D
	if root3d == null:
		return null

	var camera := root3d.get_viewport().get_camera_3d()
	if camera == null:
		return null

	var space_state := root3d.get_world_3d().direct_space_state
	var aim_from := camera.global_position
	var aim_to := aim_from + -camera.global_transform.basis.z * max_aim_distance

	var aim_hit := cast_aim_ray(space_state, aim_from, aim_to)
	if not aim_hit.is_empty():
		return aim_hit.position as Vector3

	var ground_hit := cast_aim_ray(space_state, aim_to, aim_to + Vector3.DOWN * max_ground_search_distance)
	if not ground_hit.is_empty():
		return ground_hit.position as Vector3

	return null


func cast_aim_ray(space_state: PhysicsDirectSpaceState3D, from: Vector3, to: Vector3) -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = aim_collision_mask
	if root is CollisionObject3D:
		query.exclude = [(root as CollisionObject3D).get_rid()]
	return space_state.intersect_ray(query)
