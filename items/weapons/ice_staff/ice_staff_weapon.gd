class_name IceStaffWeapon
extends ProjectileWeapon


@export_custom(PROPERTY_HINT_NONE, "suffix:m") var spawn_height_above_target := 10.0
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var min_height := 0.3
@export_flags_3d_physics var aim_collision_mask := 5

@export_group("Aim Distance", "aim_distance")
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var aim_distance_min := 0.0
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var aim_distance_max := 25.0

@export_group("Ground Search", "ground_search")
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var ground_search_distance_max := 100.0
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var ground_search_margin := 0.3

var aim_indicator: Node3D
var spell_player: AudioStreamPlayer3D


func clear_nodes() -> void:
	super()
	aim_indicator = null
	spell_player = null


func set_up_scene() -> void:
	super()
	if scene_instance == null:
		return
	aim_indicator = scene_instance.get_node(^"AimIndicator")
	spell_player = scene_instance.get_node(^"SpellPlayer")


func idle() -> void:
	if not is_instance_valid(aim_indicator):
		return

	if is_on_cooldown():
		aim_indicator.visible = false
		return

	var target_position: Variant = get_target_position()
	if target_position == null:
		aim_indicator.visible = false
		return

	aim_indicator.visible = true
	aim_indicator.global_position = (target_position as Vector3)


func start_use() -> bool:
	if spawner == null:
		return true

	var target_position: Variant = get_target_position()
	if target_position == null:
		# The cooldown starts before start_use() runs, so refund it for a rejected aim
		cooldown_start_time = -INF
		return true

	spawner.global_position = (target_position as Vector3) + Vector3.UP * spawn_height_above_target
	spawner.spawn()
	if spell_player != null:
		spell_player.play()
	return true


func get_target_position() -> Variant:
	var root3d := root as Node3D
	if root3d == null:
		return null

	var camera := root3d.get_viewport().get_camera_3d()
	if camera == null:
		return null

	var space_state := root3d.get_world_3d().direct_space_state
	var aim_from := camera.global_position
	var aim_to := aim_from + -camera.global_transform.basis.z * aim_distance_max

	var aim_hit := cast_aim_ray(space_state, aim_from, aim_to)
	var ground_from := aim_to
	if not aim_hit.is_empty():
		# Step back toward the camera so the downward ray doesn't start against the side of the hit object
		var hit_position := aim_hit.position as Vector3
		ground_from = hit_position + hit_position.direction_to(aim_from) * ground_search_margin

	var ground_hit := cast_aim_ray(space_state, ground_from, ground_from + Vector3.DOWN * ground_search_distance_max)
	if ground_hit.is_empty():
		return null

	var target := ground_hit.position as Vector3
	if target.y < min_height:
		return null

	var offset := (target - root3d.global_position) * Vector3(1.0, 0.0, 1.0)
	if offset.length_squared() < aim_distance_min * aim_distance_min:
		return null

	return target


func cast_aim_ray(space_state: PhysicsDirectSpaceState3D, from: Vector3, to: Vector3) -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = aim_collision_mask
	if root is CollisionObject3D:
		query.exclude = [(root as CollisionObject3D).get_rid()]
	return space_state.intersect_ray(query)
