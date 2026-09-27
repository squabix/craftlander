class_name VolleyAttackState
extends SpecialAttackState

const BACK_OFF_MARGIN := 3.0
const BACK_OFF_DURATION := 0.4
const BACK_OFF_SETTLE := 0.05
const MUZZLE_FALLBACK_HEIGHT := 1.4

@export var spawner: ProjectileSpawner3D

@export_group("Volley")
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var reach := 24.0
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var min_distance := 9.0
@export_custom(PROPERTY_HINT_NONE, "suffix:°") var fan := 36.0
@export var shots := 5
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var aim_height := 1.0

@export_group("Pose", "pose")
@export var pose_tell_animation := &""
@export var pose_strike_animation := &""
@export var pose_player_animation := &""
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var pose_player_release_time := 0.0
@export_custom(PROPERTY_HINT_NONE, "suffix:rad") var pose_aim_rotation := 0.15
@export_custom(PROPERTY_HINT_NONE, "suffix:rad") var pose_shoot_rotation := 0.35
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var pose_shoot_duration := 0.06

var _aim_direction := Vector3.ZERO


func get_reach() -> float:
	return reach


func run() -> void:
	_aim_direction = Vector3.ZERO
	if approach():
		return

	if not await keep_distance():
		return

	var aim := enemy.tell_time(aim_time)
	var wind_up := enemy.tell_time(tell)
	var origin := enemy.ground(enemy.global_position)
	var telegraph := start_wind_up(origin, aim + wind_up)
	if not await aim_and_tell(aim, wind_up, update_aim.bind(telegraph)):
		return
	if not await release(telegraph):
		return

	pose(0.0, 1.0, STRIKE_ANIMATION_TIME)
	recover()


func release(telegraph: PlanarTelegraph3D) -> bool:
	enemy.play_player_animation(pose_player_animation)
	if pose_player_release_time > 0.0 and not await wait(pose_player_release_time):
		return false

	telegraph.activate()
	shoot()
	return await wait(STRIKE_ANIMATION_TIME)


func keep_distance() -> bool:
	if enemy.distance_to_target() >= min_distance:
		return true

	return await back_off(min_distance + BACK_OFF_MARGIN)


func back_off(target_distance: float) -> bool:
	var target := get_target()
	if not is_instance_valid(target):
		return is_alive()

	if not await drive(enemy.global_position, target.global_position + get_away_from(target) * target_distance, BACK_OFF_DURATION):
		return false
	return await wait(BACK_OFF_SETTLE)


func start_wind_up(origin: Vector3, duration: float) -> PlanarTelegraph3D:
	var telegraph := track(PlanarTelegraphVfx.wedge(Spawner3D.root, origin, enemy.global_rotation.y, reach, deg_to_rad(fan), color, duration))
	begin_tell(pose_tell_animation, pose_aim_rotation, 1.0, duration)
	return telegraph


func update_aim(telegraph: PlanarTelegraph3D) -> void:
	_aim_direction = get_aim_direction()
	telegraph.set_yaw(Util.direction_yaw(_aim_direction))


func get_spawner() -> ProjectileSpawner3D:
	return spawner


func get_muzzle() -> Vector3:
	var muzzle := get_spawner()
	if not is_instance_valid(muzzle):
		return enemy.global_position + Vector3.UP * MUZZLE_FALLBACK_HEIGHT
	return muzzle.global_position


func get_aim_direction() -> Vector3:
	var target := get_target()
	if not is_instance_valid(target):
		return Util.yaw_direction(enemy.global_rotation.y)
	return get_muzzle().direction_to(target.global_position + Vector3.UP * aim_height)


func shoot() -> void:
	var direction := _aim_direction if _aim_direction != Vector3.ZERO else get_aim_direction()
	enemy.play_animation(pose_strike_animation)
	pose(pose_shoot_rotation, 1.0, pose_shoot_duration)
	EnemyVfx.impact(Spawner3D.root, get_muzzle(), color, direction)
	enemy.fired.emit()
	fire_fan(direction)


func fire_fan(direction: Vector3) -> void:
	var arc := deg_to_rad(fan)
	for i in shots:
		var angle := lerpf(-arc / 2.0, arc / 2.0, i / float(maxi(shots - 1, 1)))
		fire(direction.rotated(Vector3.UP, angle))


func fire(direction: Vector3) -> void:
	var muzzle := get_spawner()
	if not is_instance_valid(muzzle):
		Util.node_error("%s has no projectile spawner for its volley", enemy)
		return

	muzzle.global_basis = Basis.looking_at(direction, Vector3.UP)
	muzzle.spawn()
