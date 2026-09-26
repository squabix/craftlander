class_name CaptainComboState
extends CaptainMeleeState

const LINE := &"combo"

const ANIM_WINDUP := &"ComboWindupShot"
const ANIM_SLASH := &"SlashShot"

const WINDUP_POSE_ROTATION := 0.45
const SLASH_POSE_ROTATION := -0.55
const SLASH_POSE_DURATION := 0.08

const APPROACH_REACH_FRACTION := 0.8
const IMPACT_REACH_FRACTION := 0.55
const SECTOR_HEIGHT_TOLERANCE := 3.5
const LEAN_STOP_DISTANCE := 1.5

@export_group("Transitions")
@export var lunge_state := &"Lunge"

@export_group("Swings")
@export var swings: Array[int] = [2, 2, 3] # per phase
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var reach := 4.5
@export_custom(PROPERTY_HINT_NONE, "suffix:°") var arc := 110.0
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var followup_tell := 0.55

@export_group("Lean", "lean")
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var lean_distance := 1.4
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var lean_duration := 0.18


func run() -> void:
	if chase_if_far(reach * APPROACH_REACH_FRACTION, lunge_state):
		return

	for i in swings[captain.phase]:
		if not is_alive() or not await swing(i):
			return

	recover()


func swing(index: int) -> bool:
	var aim := captain.tell_time(aim_time)
	var wind_up := captain.tell_time(tell if index == 0 else followup_tell)
	var origin := captain.ground(captain.global_position)
	var telegraph := start_wind_up(index, origin, aim + wind_up)
	if not await aim_and_tell(aim, wind_up, func() -> void: telegraph.set_yaw(captain.global_rotation.y), true):
		return false

	telegraph.activate()
	animate_slash()
	strike(origin, captain.global_rotation.y)
	return await wait(STRIKE_ANIMATION_TIME)


func start_wind_up(index: int, origin: Vector3, duration: float) -> PlanarTelegraph3D:
	var telegraph := PlanarTelegraphVfx.wedge(Spawner3D.root, origin, captain.global_rotation.y, reach, deg_to_rad(arc), color, duration)
	begin_tell(LINE if index == 0 else &"", ANIM_WINDUP, WINDUP_POSE_ROTATION, 1.0, duration)
	return telegraph


func animate_slash() -> void:
	captain.swung.emit()
	captain.play_animation(ANIM_SLASH)
	captain.pose(SLASH_POSE_ROTATION, 1.0, SLASH_POSE_DURATION)


func strike(origin: Vector3, yaw: float) -> void:
	var slash_direction := direction_of(yaw)
	lean_forward(slash_direction)
	GhostVFX.impact(Spawner3D.root, origin + slash_direction * reach * IMPACT_REACH_FRACTION + Vector3.UP, color, slash_direction)
	if in_sector(origin, yaw):
		hurt_player(get_cutlass_damage())


func lean_forward(direction: Vector3) -> void:
	var travel := clampf(minf(lean_distance, captain.distance_to_player() - LEAN_STOP_DISTANCE), 0.0, lean_distance)
	if travel <= 0.0:
		return

	var destination := captain.global_position + direction * travel
	var tween := create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(captain, ^"global_position:x", destination.x, lean_duration)
	tween.tween_property(captain, ^"global_position:z", destination.z, lean_duration)


func in_sector(origin: Vector3, yaw: float) -> bool:
	var player := captain.get_player()
	if player == null:
		return false

	var offset := player.global_position - origin
	if absf(offset.y) > SECTOR_HEIGHT_TOLERANCE:
		return false
	offset.y = 0.0

	var distance := offset.length()
	if distance > reach + PLAYER_RADIUS:
		return false
	if distance < PLAYER_RADIUS:
		return true

	return direction_of(yaw).angle_to(offset) <= deg_to_rad(arc) / 2.0 + asin(minf(PLAYER_RADIUS / distance, 1.0))
