class_name CaptainAttackState
extends CaptainState

const STRIKE_ANIMATION_TIME := 0.3
const PLAYER_RADIUS := 0.6
const KNOCKBACK_LIFT := 0.3

@export_group("Transitions")
@export var chase_state := &"Chasing"
@export var open_state := &"Open"
@export var abort_state := &"Lull"

@export_group("Timing")
@export var color := Color(1.0, 0.2, 0.15)
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var aim_time := 0.35
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var tell := 1.2
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var recovery := 2.0

var _player_hurtbox: Hurtbox3D


static func direction_of(yaw: float) -> Vector3:
	return Vector3(-sin(yaw), 0.0, -cos(yaw))


func enter() -> void:
	captain.unlock_facing()
	super()


func chase_if_far(target_range: float, on_fail := &"", start_range := -1.0) -> bool:
	var chase := (get_parent() as StateMachine).get_state(chase_state) as CaptainChaseState
	if chase.arrived_at == name:
		chase.arrived_at = &""
		return false

	if captain.distance_to_player() <= (target_range if start_range < 0.0 else start_range):
		return false

	chase.begin(target_range, name, on_fail)
	go_to(chase_state)
	return true


func begin_tell(line: StringName, animation: StringName, pose_rotation: float, pose_scale: float, duration: float) -> void:
	captain.announce_attack(color, duration)
	if line != &"":
		captain.voice.say(line)
	if animation != &"":
		captain.play_animation(animation)
	if not is_nan(pose_rotation):
		captain.pose(pose_rotation, pose_scale, duration)


func aim_and_tell(aim_seconds: float, tell_seconds: float, step := Callable(), snap_to_player := false) -> bool:
	if aim_seconds > 0.0 and not await follow_player(aim_seconds, step, snap_to_player):
		return false
	return await wait(tell_seconds)


func follow_player(duration: float, step: Callable, snap_to_player: bool) -> bool:
	captain.unlock_facing()
	if snap_to_player:
		captain.face_player_now()

	var elapsed := 0.0
	while elapsed < duration:
		await get_tree().physics_frame
		if not is_alive():
			return false

		elapsed += get_physics_process_delta_time()
		if snap_to_player:
			captain.face_player_now()
		if step.is_valid():
			step.call()

	captain.lock_facing()
	return true


func hurt_player(damage: Damage) -> void:
	var player := captain.get_player()
	if player == null:
		return

	if not is_instance_valid(_player_hurtbox):
		_player_hurtbox = Util.find_child_of_class(player, &"Hurtbox3D") as Hurtbox3D

	if is_instance_valid(_player_hurtbox):
		_player_hurtbox.hurt(damage, get_knockback_direction(player))
	else:
		player.health.hurt(damage.base_amount)


func get_knockback_direction(player: Player) -> Vector3:
	var direction := player.global_position - captain.global_position
	direction.y = 0.0
	return (direction.normalized() + Vector3.UP * KNOCKBACK_LIFT).normalized()


func recover() -> void:
	var open := (get_parent() as StateMachine).get_state(open_state) as CaptainOpenState
	open.duration = recovery
	go_to(open_state)


func abort() -> void:
	go_to(abort_state)
