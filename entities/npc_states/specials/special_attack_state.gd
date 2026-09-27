class_name SpecialAttackState
extends SequenceState

const STRIKE_ANIMATION_TIME := 0.3
const TARGET_RADIUS := 0.6
const KNOCKBACK_LIFT := 0.3
const WALL_BLOCK_DOT := -0.7
const AWAY_DEADZONE_SQUARED := 0.01

@export var voice_line := &""

@export_group("Transitions")
@export var open_state := &"Open"
@export var abort_state := &"Chasing"

@export_group("Range", "range")
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var range_min := 0.0
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var range_max := 4.0

@export_group("Approach", "approach")
@export var approach_state := &""
@export var approach_fail_state := &""
@export_range(0.0, 1.0) var approach_fraction := 0.8
@export var approach_starts_beyond_reach := false

@export_group("Timing")
@export var color := Color(1.0, 0.2, 0.15)
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var aim_time := 0.35
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var tell := 1.2
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var recovery := 2.0

@export_group("Damage")
@export var weapon_holder: ItemHolder3D
@export_custom(PROPERTY_HINT_NONE, "suffix:dp") var damage := 10.0
@export var knockback := 10.0

var enemy: Enemy3D:
	get:
		return root as Enemy3D

var _target_hurtbox: Hurtbox3D
var _telegraphs: Array[PlanarTelegraph3D] = []


func _exit_tree() -> void:
	dismiss_telegraphs()


func enter() -> void:
	enemy.unlock_facing()
	super()


func exit() -> void:
	enemy.release_velocity()
	dismiss_telegraphs()


func can_start(distance: float) -> bool:
	return distance >= range_min and distance <= range_max


func get_target() -> Node3D:
	return enemy.get_target()


func get_reach() -> float:
	return range_max


func approach() -> bool:
	if approach_state == &"":
		return false

	var chase := (get_parent() as StateMachine).get_state(approach_state) as ChaseToRangeState
	if chase.arrived_at == name:
		chase.arrived_at = &""
		return false

	var target_range := get_reach() * approach_fraction
	if enemy.distance_to_target() <= (get_reach() if approach_starts_beyond_reach else target_range):
		return false

	chase.begin(target_range, name, approach_fail_state)
	go_to(approach_state)
	return true


func dismiss_telegraphs() -> void:
	for telegraph in _telegraphs:
		if is_instance_valid(telegraph):
			telegraph.dismiss()
	_telegraphs.clear()


func track(telegraph: PlanarTelegraph3D) -> PlanarTelegraph3D:
	_telegraphs.append(telegraph)
	return telegraph


func pose(rotation_x: float, scale_y: float, duration: float) -> void:
	if enemy.special_poses:
		enemy.pose(rotation_x, scale_y, duration)


func begin_tell(animation: StringName, pose_rotation: float, pose_scale: float, duration: float, line := voice_line) -> void:
	enemy.announce_attack(color, duration)
	if line != &"":
		enemy.say(line)
	enemy.play_animation(animation)
	if not is_nan(pose_rotation):
		pose(pose_rotation, pose_scale, duration)


func aim_and_tell(aim_seconds: float, tell_seconds: float, step := Callable(), snap_to_target := false) -> bool:
	if aim_seconds > 0.0 and not await follow_target(aim_seconds, step, snap_to_target):
		return false
	return await wait(tell_seconds)


func follow_target(duration: float, step: Callable, snap_to_target: bool) -> bool:
	enemy.unlock_facing()
	aim_at_target(0.0, snap_to_target)

	var elapsed := 0.0
	while elapsed < duration:
		await get_tree().physics_frame
		if not is_alive():
			return false

		var delta := get_physics_process_delta_time()
		elapsed += delta
		aim_at_target(delta, snap_to_target)
		if step.is_valid():
			step.call()

	enemy.lock_facing()
	return true


func aim_at_target(delta: float, snap: bool) -> void:
	var target := get_target()
	if is_instance_valid(target):
		enemy.aim_toward(target.global_position, delta, snap)


func drive(from: Vector3, to: Vector3, duration: float, trans := Tween.TRANS_SINE, easing := Tween.EASE_OUT, step := Callable()) -> bool:
	var heading := get_planar_offset(from, to).normalized()

	var elapsed := 0.0
	while elapsed < duration:
		await get_tree().physics_frame
		if not is_alive():
			break

		var delta := get_physics_process_delta_time()
		elapsed = minf(elapsed + delta, duration)
		steer_toward(from.lerp(to, Tween.interpolate_value(0.0, 1.0, elapsed, duration, trans, easing)), delta)

		if step.is_valid():
			step.call()
		if is_blocked_by_wall(heading):
			break

	enemy.release_velocity()
	return is_alive()


func steer_toward(goal: Vector3, delta: float) -> void:
	enemy.force_planar_velocity(get_planar_offset(enemy.global_position, goal) / delta)


func is_blocked_by_wall(heading: Vector3) -> bool:
	return enemy.is_on_wall() and enemy.get_wall_normal().dot(heading) < WALL_BLOCK_DOT


func get_planar_offset(from: Vector3, to: Vector3) -> Vector3:
	var offset := to - from
	offset.y = 0.0
	return offset


func get_away_from(target: Node3D) -> Vector3:
	var away := get_planar_offset(target.global_position, enemy.global_position)
	return Vector3.BACK if away.length_squared() < AWAY_DEADZONE_SQUARED else away.normalized()


func hop_visuals(height: float, duration: float) -> void:
	var tween := create_tween().set_trans(Tween.TRANS_SINE)
	tween.tween_property(enemy.visuals, ^"position:y", height, duration * 0.5).as_relative().set_ease(Tween.EASE_OUT)
	tween.tween_property(enemy.visuals, ^"position:y", -height, duration * 0.5).as_relative().set_ease(Tween.EASE_IN)


func get_damage(multiplier := 1.0) -> Damage:
	var hit: Damage
	var tool := weapon_holder.get_held_item() as HarvestingTool if is_instance_valid(weapon_holder) else null
	if tool != null and tool.damage != null:
		hit = tool.damage.duplicate()
	else:
		hit = Damage.from_base(damage)
		hit.knockback_force = knockback

	hit.base_amount *= multiplier
	hit.knockback_force *= multiplier
	hit.source = enemy
	return hit


func hurt_target(hit: Damage) -> void:
	var target := get_target()
	if not is_instance_valid(target):
		return

	var hurtbox := find_target_hurtbox(target)
	if is_instance_valid(hurtbox):
		hurtbox.hurt(hit, get_knockback_direction(target))
		return

	var health := Health.search(target)
	if is_instance_valid(health):
		health.hurt(hit.base_amount)


func find_target_hurtbox(target: Node3D) -> Hurtbox3D:
	if not is_instance_valid(_target_hurtbox) or _target_hurtbox.get_parent() != target:
		_target_hurtbox = Util.find_child_of_class(target, &"Hurtbox3D") as Hurtbox3D
	return _target_hurtbox


func get_knockback_direction(target: Node3D) -> Vector3:
	var direction := get_planar_offset(enemy.global_position, target.global_position)
	return (direction.normalized() + Vector3.UP * KNOCKBACK_LIFT).normalized()


func recover() -> void:
	var open := (get_parent() as StateMachine).get_state(open_state) as OpenState
	if open == null:
		recover_in_place()
		return

	open.duration = recovery
	go_to(open_state)


func recover_in_place() -> void:
	if await wait(recovery * enemy.recovery_scale()):
		go_to(abort_state)


func abort() -> void:
	go_to(abort_state)
