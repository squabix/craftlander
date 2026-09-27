class_name ComboAttackState
extends SpecialAttackState

const IMPACT_REACH_FRACTION := 0.55
const SECTOR_HEIGHT_TOLERANCE := 3.5
const LEAN_STOP_DISTANCE := 1.5

@export_group("Swings")
@export var swings := 2
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var reach := 4.5
@export_custom(PROPERTY_HINT_NONE, "suffix:°") var arc := 110.0
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var followup_tell := 0.55

@export_group("Lean", "lean")
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var lean_distance := 1.4
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var lean_duration := 0.18

@export_group("Pose", "pose")
@export var pose_tell_animation := &""
@export var pose_strike_animation := &""
@export_custom(PROPERTY_HINT_NONE, "suffix:rad") var pose_windup_rotation := 0.45
@export_custom(PROPERTY_HINT_NONE, "suffix:rad") var pose_slash_rotation := -0.55
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var pose_slash_duration := 0.08


func get_reach() -> float:
	return reach


func get_swing_count() -> int:
	return swings


func run() -> void:
	if approach():
		return

	for i in get_swing_count():
		if not is_alive() or not await swing(i):
			return

	pose(0.0, 1.0, STRIKE_ANIMATION_TIME)
	recover()


func swing(index: int) -> bool:
	var aim := enemy.tell_time(aim_time)
	var wind_up := enemy.tell_time(tell if index == 0 else followup_tell)
	var origin := enemy.ground(enemy.global_position)
	var telegraph := start_wind_up(index, origin, aim + wind_up)
	if not await aim_and_tell(aim, wind_up, func() -> void: telegraph.set_yaw(enemy.global_rotation.y), true):
		return false

	telegraph.activate()
	animate_slash()
	strike(origin, enemy.global_rotation.y)
	return await wait(STRIKE_ANIMATION_TIME)


func start_wind_up(index: int, origin: Vector3, duration: float) -> PlanarTelegraph3D:
	var telegraph := track(PlanarTelegraphVfx.wedge(Spawner3D.root, origin, enemy.global_rotation.y, reach, deg_to_rad(arc), color, duration))
	begin_tell(pose_tell_animation, pose_windup_rotation, 1.0, duration, voice_line if index == 0 else &"")
	return telegraph


func animate_slash() -> void:
	enemy.swung.emit()
	enemy.play_animation(pose_strike_animation)
	pose(pose_slash_rotation, 1.0, pose_slash_duration)


func strike(origin: Vector3, yaw: float) -> void:
	var slash_direction := Util.yaw_direction(yaw)
	lean_forward(slash_direction)
	EnemyVfx.impact(Spawner3D.root, origin + slash_direction * reach * IMPACT_REACH_FRACTION + Vector3.UP, color, slash_direction)

	var target := get_target()
	if is_instance_valid(target) and Util.in_planar_sector(origin, yaw, target.global_position, reach, deg_to_rad(arc), TARGET_RADIUS, SECTOR_HEIGHT_TOLERANCE):
		hurt_target(get_damage())


func lean_forward(direction: Vector3) -> void:
	var travel := clampf(minf(lean_distance, enemy.distance_to_target() - LEAN_STOP_DISTANCE), 0.0, lean_distance)
	if travel > 0.0:
		drive(enemy.global_position, enemy.global_position + direction * travel, lean_duration, Tween.TRANS_QUAD, Tween.EASE_OUT)
