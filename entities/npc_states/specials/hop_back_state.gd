class_name HopBackState
extends SpecialAttackState

const SETTLE_POSE_TIME := 0.25
const DIRECTION_SPREAD := 0.8
const IMPACT_HEIGHT := 0.5

@export var next_state := &"Chasing"

@export_group("Hop")
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var min_distance := 5.0
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var max_distance := 9.0
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var duration := 0.6
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var hop_height := 0.0

@export_group("Pose", "pose")
@export_custom(PROPERTY_HINT_NONE, "suffix:rad") var pose_rotation := 0.25


func run() -> void:
	var target := get_target()
	if not is_instance_valid(target):
		go_to(next_state)
		return

	if voice_line != &"":
		enemy.say(voice_line)
	if not await hop_away(pick_destination(target)):
		return

	pose(0.0, 1.0, SETTLE_POSE_TIME)
	puff()
	go_to(next_state)


func pick_destination(target: Node3D) -> Vector3:
	var away := get_away_from(target)
	return enemy.pick_land_point(enemy.global_position, min_distance, max_distance, atan2(away.z, away.x), DIRECTION_SPREAD)


func hop_away(destination: Vector3) -> bool:
	puff()
	pose(pose_rotation, 1.0, duration)
	if hop_height > 0.0:
		hop_visuals(hop_height, duration)
	return await drive(enemy.global_position, destination, duration)


func puff() -> void:
	EnemyVfx.impact(Spawner3D.root, enemy.global_position + Vector3.UP * IMPACT_HEIGHT, color)
