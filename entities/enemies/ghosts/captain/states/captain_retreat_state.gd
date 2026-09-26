class_name CaptainRetreatState
extends CaptainState

const LINE := &"retreat"

const POSE_ROTATION := 0.25
const SETTLE_POSE_TIME := 0.25

const DIRECTION_SPREAD := 0.8
const IMPACT_HEIGHT := 0.5

@export var next_state := &"Lull"

@export_group("Retreat")
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var min_distance := 5.0
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var max_distance := 9.0
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var duration := 0.6


func run() -> void:
	var player := captain.get_player()
	if player == null:
		go_to(next_state)
		return

	captain.voice.say(LINE)
	var destination := pick_destination(player)
	puff()
	slide_to(destination)
	if not await wait(duration):
		return

	captain.pose(0.0, 1.0, SETTLE_POSE_TIME)
	puff()
	go_to(next_state)


func pick_destination(player: Player) -> Vector3:
	var away := captain.global_position - player.global_position
	away.y = 0.0
	if away.length_squared() < 0.01:
		away = Vector3.BACK

	var away_angle := atan2(away.z, away.x)
	return captain.pick_land_point(captain.global_position, min_distance, max_distance, away_angle, DIRECTION_SPREAD)


func slide_to(destination: Vector3) -> void:
	var tween := create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(captain, ^"global_position:x", destination.x, duration)
	tween.tween_property(captain, ^"global_position:z", destination.z, duration)
	captain.pose(POSE_ROTATION, 1.0, duration)


func puff() -> void:
	GhostVFX.impact(Spawner3D.root, captain.global_position + Vector3.UP * IMPACT_HEIGHT, GhostCaptain.PHASE_COLORS[captain.phase])
