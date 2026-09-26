class_name CaptainLungeState
extends CaptainMeleeState

const LINE := &"lunge"

const ANIM_WINDUP := &"LungeWindupShot"
const ANIM_STAB := &"StabShot"

const WINDUP_POSE_ROTATION := -0.35
const WINDUP_POSE_SCALE := 0.8
const DASH_POSE_ROTATION := -0.6
const DASH_POSE_DURATION := 0.1

const DASH_STEP := 0.03
const APPROACH_LENGTH_FRACTION := 0.85
const SHOCKWAVE_RADIUS := 5.0

@export_group("Dash")
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var length := 13.0
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var width := 2.6
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var dash_duration := 0.3
@export var damage_multiplier := 1.33


func run() -> void:
	if chase_if_far(length * APPROACH_LENGTH_FRACTION):
		return

	var aim := captain.tell_time(aim_time)
	var wind_up := captain.tell_time(tell)
	var origin := captain.ground(captain.global_position)
	var telegraph := start_wind_up(origin, aim + wind_up)
	if not await aim_and_tell(aim, wind_up, func() -> void: telegraph.set_yaw(captain.global_rotation.y)):
		return

	var direction := direction_of(captain.global_rotation.y)
	telegraph.activate()
	animate_stab(origin, direction)
	if not await dash(origin, direction):
		return

	GhostVFX.shockwave(Spawner3D.root, captain.ground(captain.global_position), color, SHOCKWAVE_RADIUS)
	recover()


func start_wind_up(origin: Vector3, duration: float) -> PlanarTelegraph3D:
	var telegraph := PlanarTelegraphVfx.rectangle(Spawner3D.root, origin, captain.global_rotation.y, Vector2(width, length), color, duration)
	begin_tell(LINE, ANIM_WINDUP, WINDUP_POSE_ROTATION, WINDUP_POSE_SCALE, duration)
	return telegraph


func animate_stab(origin: Vector3, direction: Vector3) -> void:
	captain.swung.emit()
	captain.play_animation(ANIM_STAB)
	GhostVFX.impact(Spawner3D.root, origin, color, -direction)


func dash(start: Vector3, direction: Vector3) -> bool:
	slide(start + direction * length)
	captain.pose(DASH_POSE_ROTATION, 1.0, DASH_POSE_DURATION)

	var elapsed := 0.0
	var landed := false
	while elapsed < dash_duration:
		if not await wait(DASH_STEP):
			return false

		elapsed += DASH_STEP
		GhostVFX.impact(Spawner3D.root, captain.global_position + Vector3.UP, color)
		if not landed and is_crossing_player(start):
			landed = true
			hurt_player(get_cutlass_damage(damage_multiplier))

	return true


func slide(destination: Vector3) -> void:
	var tween := create_tween().set_parallel(true).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tween.tween_property(captain, ^"global_position:x", destination.x, dash_duration)
	tween.tween_property(captain, ^"global_position:z", destination.z, dash_duration)


func is_crossing_player(start: Vector3) -> bool:
	return distance_to_segment(start, captain.global_position) <= width * 0.5 + PLAYER_RADIUS


func distance_to_segment(from: Vector3, to: Vector3) -> float:
	var player := captain.get_player()
	if player == null:
		return INF

	var point := Vector2(player.global_position.x, player.global_position.z)
	return point.distance_to(Geometry2D.get_closest_point_to_segment(point, Vector2(from.x, from.z), Vector2(to.x, to.z)))
