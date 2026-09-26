class_name CaptainVolleyState
extends CaptainAttackState

const LINE := &"volley"

const ANIM_AIM := &"AimShot"
const ANIM_SHOOT := &"ShootShot"

const AIM_POSE_ROTATION := 0.15
const SHOOT_POSE_ROTATION := 0.35
const SHOOT_POSE_DURATION := 0.06
const CANNON_BLEND_TIME := 0.3

const APPROACH_REACH_FRACTION := 0.7
const BACK_OFF_MARGIN := 3.0
const BACK_OFF_DURATION := 0.4
const BACK_OFF_SETTLE := 0.45
const MUZZLE_FALLBACK_HEIGHT := 1.4

@export var cannon_holder: ItemHolder3D

@export_group("Volley")
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var reach := 24.0
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var min_distance := 9.0
@export_custom(PROPERTY_HINT_NONE, "suffix:°") var fan := 36.0
@export var shots := 5
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var aim_height := 1.0


func run() -> void:
	if chase_if_far(reach * APPROACH_REACH_FRACTION, &"", reach):
		return

	if not await keep_distance():
		return

	var aim := captain.tell_time(aim_time)
	var wind_up := captain.tell_time(tell)
	var origin := captain.ground(captain.global_position)
	var telegraph := start_wind_up(origin, aim + wind_up)
	if not await aim_and_tell(aim, wind_up, aim_at_player.bind(telegraph)):
		return

	telegraph.activate()
	shoot()
	if not await wait(STRIKE_ANIMATION_TIME):
		return

	recover()


func keep_distance() -> bool:
	if captain.distance_to_player() >= min_distance:
		return true

	await back_off(min_distance + BACK_OFF_MARGIN)
	return is_alive()


func start_wind_up(origin: Vector3, duration: float) -> PlanarTelegraph3D:
	var telegraph := PlanarTelegraphVfx.wedge(Spawner3D.root, origin, captain.global_rotation.y, reach, deg_to_rad(fan), color, duration)
	begin_tell(LINE, ANIM_AIM, AIM_POSE_ROTATION, 1.0, duration)
	captain.cannon_aim.raise(CANNON_BLEND_TIME)
	return telegraph


func aim_at_player(telegraph: PlanarTelegraph3D) -> void:
	var player := captain.get_player()
	if player != null:
		captain.cannon_aim.aim_point = player.global_position + Vector3.UP * aim_height

	var direction := captain.cannon_aim.get_aim_direction()
	telegraph.set_yaw(atan2(-direction.x, -direction.z))


func shoot() -> void:
	var direction := captain.cannon_aim.get_aim_direction()
	captain.play_animation(ANIM_SHOOT)
	captain.cannon_aim.lower(CANNON_BLEND_TIME)
	captain.pose(SHOOT_POSE_ROTATION, 1.0, SHOOT_POSE_DURATION)
	GhostVFX.impact(Spawner3D.root, get_muzzle(), color, direction)
	captain.cannon_fired.emit()
	fire_fan(direction)


func fire_fan(direction: Vector3) -> void:
	var arc := deg_to_rad(fan)
	for i in shots:
		var angle := lerpf(-arc / 2.0, arc / 2.0, i / float(maxi(shots - 1, 1)))
		fire_cannon(direction.rotated(Vector3.UP, angle))


func get_cannon_spawner() -> ProjectileSpawner3D:
	var weapon := cannon_holder.get_held_item() as ProjectileWeapon
	return null if weapon == null else weapon.spawner


func get_muzzle() -> Vector3:
	var spawner := get_cannon_spawner()
	if spawner == null:
		return captain.global_position + Vector3.UP * MUZZLE_FALLBACK_HEIGHT
	return spawner.global_position


func fire_cannon(direction: Vector3) -> void:
	var spawner := get_cannon_spawner()
	if spawner == null:
		Util.node_error("%s has no cannon to fire", captain)
		return

	spawner.global_basis = Basis.looking_at(direction, Vector3.UP)
	spawner.spawn()


func back_off(target_distance: float) -> void:
	var player := captain.get_player()
	var away := captain.global_position - player.global_position
	away.y = 0.0
	if away.length_squared() < 0.01:
		away = Vector3.BACK

	slide_to(player.global_position + away.normalized() * target_distance)
	await wait(BACK_OFF_SETTLE)


func slide_to(destination: Vector3) -> void:
	var tween := create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(captain, ^"global_position:x", destination.x, BACK_OFF_DURATION)
	tween.tween_property(captain, ^"global_position:z", destination.z, BACK_OFF_DURATION)
