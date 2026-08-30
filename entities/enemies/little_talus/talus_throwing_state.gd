class_name TalusThrowingState
extends RangedAttackState

@export var left_attack_anim := &"attack_left"
@export var right_attack_anim := &"attack_right"

@export var left_arm: Node3D
@export var right_arm: Node3D
@export var left_spawner: ProjectileSpawner3D
@export var right_spawner: ProjectileSpawner3D

@export_custom(PROPERTY_HINT_NONE, "suffix:s") var regrow_delay := 0.35
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var regrow_anim_duration := 0.3

const _LEFT_REST_POSITION := Vector3(-0.9, 0, 0)
const _RIGHT_REST_POSITION := Vector3(0.9, 0, 0)
const _REGROW_START_SCALE := 0.05

var _next_is_left := true
var _left_regrow_tween: Tween
var _right_regrow_tween: Tween


func exit() -> void:
	super()
	_snap_regrow_left()
	_snap_regrow_right()


func _get_attack_animation() -> StringName:
	var anim_name := left_attack_anim if _next_is_left else right_attack_anim
	_next_is_left = not _next_is_left
	return anim_name


func _is_attack_animation(anim_name: StringName) -> bool:
	return anim_name == left_attack_anim or anim_name == right_attack_anim


func _release_left() -> void:
	_release(left_arm, left_spawner, _animate_regrow_left)


func _release_right() -> void:
	_release(right_arm, right_spawner, _animate_regrow_right)


func _release(arm: Node3D, spawner: ProjectileSpawner3D, regrow: Callable) -> void:
	if is_instance_valid(arm):
		arm.visible = false
	if is_instance_valid(spawner):
		spawner.look_at(get_aim_position(), Vector3.UP)
		spawner.spawn()

	# Regrowing happens on its own timer, independent of the attack animation's
	# length, so the entity is free to move again as soon as the throw itself
	# finishes rather than waiting for the arm to visually regrow.
	await get_tree().create_timer(regrow_delay).timeout

	# is_active can have gone false while waiting (e.g. lost the target and left
	# Throwing for Chasing/Searching) — exit() already snapped the arm back
	# instantly in that case.
	if not is_active:
		return
	regrow.call()


func _animate_regrow_left() -> void:
	_left_regrow_tween = _animate_regrow(left_arm, _LEFT_REST_POSITION, _left_regrow_tween)


func _animate_regrow_right() -> void:
	_right_regrow_tween = _animate_regrow(right_arm, _RIGHT_REST_POSITION, _right_regrow_tween)


func _animate_regrow(arm: Node3D, rest_position: Vector3, tween: Tween) -> Tween:
	if is_instance_valid(tween):
		tween.kill()
	if not is_instance_valid(arm):
		return null

	# Snap the arm to the head/center before growing it back out, so it reads
	# as emerging from the body rather than fading in at its resting spot.
	arm.visible = true
	arm.rotation = Vector3.ZERO
	arm.scale = Vector3.ONE * _REGROW_START_SCALE
	arm.position = Vector3.ZERO

	var new_tween := create_tween()
	new_tween.set_parallel(true)
	new_tween.tween_property(arm, "scale", Vector3.ONE, regrow_anim_duration)
	new_tween.tween_property(arm, "position", rest_position, regrow_anim_duration)
	return new_tween


func _snap_regrow_left() -> void:
	_left_regrow_tween = _snap_regrow(left_arm, _LEFT_REST_POSITION, _left_regrow_tween)


func _snap_regrow_right() -> void:
	_right_regrow_tween = _snap_regrow(right_arm, _RIGHT_REST_POSITION, _right_regrow_tween)


func _snap_regrow(arm: Node3D, rest_position: Vector3, tween: Tween) -> Tween:
	if is_instance_valid(tween):
		tween.kill()
	if is_instance_valid(arm):
		arm.visible = true
		arm.rotation = Vector3.ZERO
		arm.scale = Vector3.ONE
		arm.position = rest_position
	return null
