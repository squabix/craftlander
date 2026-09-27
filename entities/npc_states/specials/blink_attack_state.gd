class_name BlinkAttackState
extends SpecialAttackState

const ARRIVAL_HEIGHT := 0.8
const SHOCKWAVE_RADIUS_SCALE := 1.6
const LEAP_CROUCH_ROTATION := 0.3
const LEAP_CROUCH_SCALE := 0.8
const DRY_LANDING_TRIES := 4

@export_group("Blink")
@export var vanish := true
@export var land_near_target := true
@export var require_dry_landing := false
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var min_distance := 4.0
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var max_distance := 8.0
@export_custom(PROPERTY_HINT_NONE, "suffix:rad") var land_spread := PI
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var radius := 3.2

@export_group("Leap", "leap")
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var leap_duration := 0.5
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var leap_height := 3.0
@export var leap_landing_spawner: Spawner3D

@export_group("Pose", "pose")
@export var pose_tell_animation := &""
@export var pose_leap_animation := &""
@export var pose_arrival_animation := &""
@export_custom(PROPERTY_HINT_NONE, "suffix:rad") var pose_arrival_rotation := -0.5
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var pose_arrival_duration := 0.08


func run() -> void:
	var target := get_target()
	if not is_instance_valid(target):
		abort()
		return

	var destination := pick_landing(target)
	if require_dry_landing and not enemy.is_dry(destination):
		abort()
		return

	var wind_up := enemy.tell_time(tell)
	var ring := track(PlanarTelegraphVfx.disc(Spawner3D.root, destination, radius, color, get_fill_time(wind_up)))
	if not await travel(destination, wind_up):
		return

	arrive(destination, ring)
	if not await wait(STRIKE_ANIMATION_TIME):
		return

	pose(0.0, 1.0, STRIKE_ANIMATION_TIME)
	recover()


func pick_landing(target: Node3D) -> Vector3:
	var destination := pick_destination(target)
	for i in DRY_LANDING_TRIES if require_dry_landing else 0:
		if enemy.is_dry(destination):
			break
		destination = pick_destination(target)
	return destination


func pick_destination(target: Node3D) -> Vector3:
	if land_near_target:
		return enemy.pick_land_point(target.global_position, min_distance, max_distance, 0.0, land_spread)

	var away := get_away_from(target)
	return enemy.pick_land_point(target.global_position, min_distance, max_distance, atan2(away.z, away.x), land_spread)


func get_fill_time(wind_up: float) -> float:
	return wind_up if vanish else wind_up + leap_duration


func travel(destination: Vector3, wind_up: float) -> bool:
	if vanish:
		disappear(wind_up)
		return await wait(wind_up)

	if not await crouch(wind_up):
		return false
	return await leap(destination)


func disappear(wind_up: float) -> void:
	begin_tell(&"", NAN, 1.0, wind_up)
	EnemyVfx.teleport(Spawner3D.root, enemy.global_position + Vector3.UP, color)
	enemy.teleported.emit()
	enemy.vanish()


func crouch(wind_up: float) -> bool:
	begin_tell(pose_tell_animation, LEAP_CROUCH_ROTATION, LEAP_CROUCH_SCALE, wind_up)
	return await follow_target(wind_up, Callable(), true)


func leap(destination: Vector3) -> bool:
	pose(0.0, 1.0, leap_duration * 0.5)
	enemy.play_animation(pose_leap_animation)
	if leap_height > 0.0:
		hop_visuals(leap_height, leap_duration)
	return await drive(enemy.global_position, destination, leap_duration, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)


func arrive(destination: Vector3, ring: PlanarTelegraph3D) -> void:
	if vanish:
		reappear(destination)
	elif is_instance_valid(leap_landing_spawner):
		leap_landing_spawner.spawn()

	ring.activate()
	enemy.play_animation(pose_arrival_animation)
	pose(pose_arrival_rotation, 1.0, pose_arrival_duration)
	if damage > 0.0:
		slam(destination)


func reappear(destination: Vector3) -> void:
	enemy.global_position = destination + Vector3.UP * ARRIVAL_HEIGHT
	enemy.appear()
	enemy.teleported.emit()
	EnemyVfx.teleport(Spawner3D.root, destination + Vector3.UP, color)


func slam(center: Vector3) -> void:
	EnemyVfx.shockwave(Spawner3D.root, center, color, radius * SHOCKWAVE_RADIUS_SCALE)
	hurt_if_in_radius(center)


func hurt_if_in_radius(center: Vector3) -> void:
	var target := get_target()
	if not is_instance_valid(target):
		return

	if get_planar_offset(center, target.global_position).length() <= radius + TARGET_RADIUS:
		hurt_target(get_damage())
