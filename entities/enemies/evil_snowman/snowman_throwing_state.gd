class_name SnowmanThrowingState
extends RangedAttackState

@export var left_spawner: ProjectileSpawner3D
@export var right_spawner: ProjectileSpawner3D

@export_custom(PROPERTY_HINT_NONE, "suffix:s") var attack_anim_duration := 1.0

const _LEFT_REQUEST_PATH := "parameters/AttackLeftOneShot/request"
const _RIGHT_REQUEST_PATH := "parameters/AttackRightOneShot/request"

var _next_is_left := true


func enter() -> void:
	if is_instance_valid(hurt_trigger):
		hurt_trigger.disabled = true

	var remaining_sec := throw_cooldown - (Time.get_ticks_msec() - _last_attack_msec) / 1000.0
	if remaining_sec > 0.0:
		await get_tree().create_timer(remaining_sec).timeout
		if not is_active:
			return
	_start_attack()


func exit() -> void:
	if is_instance_valid(hurt_trigger):
		hurt_trigger.disabled = false


func _release_left() -> void:
	_release(left_spawner)


func _release_right() -> void:
	_release(right_spawner)


func _release(spawner: ProjectileSpawner3D) -> void:
	if is_instance_valid(spawner):
		spawner.look_at(get_aim_position(), Vector3.UP)
		spawner.spawn()


func _start_attack() -> void:
	_last_attack_msec = Time.get_ticks_msec()

	if is_instance_valid(anim_tree):
		var request_path := _LEFT_REQUEST_PATH if _next_is_left else _RIGHT_REQUEST_PATH
		anim_tree.set(request_path, AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
	_next_is_left = not _next_is_left

	await get_tree().create_timer(attack_anim_duration).timeout
	if not is_active:
		return
	if is_instance_valid(health) and health.dead:
		return
	if not can_see_target() or not is_target_in_range():
		transition_to(return_to_chase_state)
		return

	await get_tree().create_timer(throw_cooldown).timeout
	if not is_active:
		return
	if not can_see_target() or not is_target_in_range():
		transition_to(return_to_chase_state)
		return
	_start_attack()
