class_name DashAttackState
extends SpecialAttackState

const IMPACT_INTERVAL := 0.03

@export_group("Dash")
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var length := 13.0
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var width := 2.6
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var dash_duration := 0.3
@export var damage_multiplier := 1.33
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var shockwave_radius := 5.0

@export_group("Pose", "pose")
@export var pose_tell_animation := &""
@export var pose_strike_animation := &""

@export_subgroup("Windup", "pose_windup")
@export_custom(PROPERTY_HINT_NONE, "suffix:rad") var pose_windup_rotation := -0.35
@export var pose_windup_scale := 0.8

@export_subgroup("Dash", "pose_dash")
@export_custom(PROPERTY_HINT_NONE, "suffix:rad") var pose_dash_rotation := -0.6
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var pose_dash_duration := 0.1

var _telegraph: PlanarTelegraph3D
var _has_hit := false
var _since_impact := 0.0


func get_reach() -> float:
	return length


func run() -> void:
	if approach():
		return

	var origin := enemy.ground(enemy.global_position)
	if not await aim_dash(origin):
		return
	if not await strike(origin):
		return

	EnemyVfx.shockwave(Spawner3D.root, enemy.ground(enemy.global_position), color, shockwave_radius)
	recover()


func aim_dash(origin: Vector3) -> bool:
	var aim := enemy.tell_time(aim_time)
	var wind_up := enemy.tell_time(tell)
	_telegraph = start_wind_up(origin, aim + wind_up)
	return await aim_and_tell(aim, wind_up, face_telegraph)


func face_telegraph() -> void:
	_telegraph.set_yaw(enemy.global_rotation.y)


func strike(origin: Vector3) -> bool:
	var direction := Util.yaw_direction(enemy.global_rotation.y)
	_telegraph.activate()
	animate_strike(origin, direction)
	return await dash(origin, direction)


func start_wind_up(origin: Vector3, duration: float) -> PlanarTelegraph3D:
	var telegraph := track(PlanarTelegraphVfx.rectangle(Spawner3D.root, origin, enemy.global_rotation.y, Vector2(width, length), color, duration))
	begin_tell(pose_tell_animation, pose_windup_rotation, pose_windup_scale, duration)
	return telegraph


func animate_strike(origin: Vector3, direction: Vector3) -> void:
	enemy.swung.emit()
	enemy.play_animation(pose_strike_animation)
	EnemyVfx.impact(Spawner3D.root, origin, color, -direction)


func dash(start: Vector3, direction: Vector3) -> bool:
	pose(pose_dash_rotation, 1.0, pose_dash_duration)

	_has_hit = false
	_since_impact = 0.0

	var destination := start + direction * length
	if not await drive(enemy.global_position, destination, dash_duration, Tween.TRANS_EXPO, Tween.EASE_OUT, dash_step.bind(start)):
		return false

	pose(0.0, 1.0, pose_dash_duration)
	return true


func dash_step(start: Vector3) -> void:
	trail_impacts()
	if not _has_hit and is_crossing_target(start):
		_has_hit = true
		hurt_target(get_damage(damage_multiplier))


func trail_impacts() -> void:
	_since_impact += get_physics_process_delta_time()
	if _since_impact >= IMPACT_INTERVAL:
		_since_impact = 0.0
		EnemyVfx.impact(Spawner3D.root, enemy.global_position + Vector3.UP, color)


func is_crossing_target(start: Vector3) -> bool:
	var target := get_target()
	if not is_instance_valid(target):
		return false
	return Util.planar_distance_to_segment(target.global_position, start, enemy.global_position) <= width * 0.5 + TARGET_RADIUS
