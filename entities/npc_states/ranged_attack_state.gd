class_name RangedAttackState
extends TargetingState

@export var anim_player: AnimationPlayer
@export var anim_tree: AnimationTree
@export var hurt_trigger: SignalTrigger
@export var health: Health

@export var attack_anim := &"attack"
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var max_range := 14.0
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var throw_cooldown := 1.2
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var aim_height_offset := 1.0

@export_group("Target Losing")
@export var return_to_chase_state := &""

# Far enough in the past that the very first attack is never delayed.
var _last_attack_msec := -2000000000


func enter() -> void:
	if is_instance_valid(anim_tree):
		anim_tree.active = false
	if is_instance_valid(anim_player):
		anim_player.active = true
	if is_instance_valid(anim_player) and not anim_player.animation_finished.is_connected(_on_animation_finished):
		anim_player.animation_finished.connect(_on_animation_finished)
	if is_instance_valid(hurt_trigger):
		hurt_trigger.disabled = true

	# Re-entering this state (e.g. bouncing back from Chasing) must not let an
	# attack fire sooner than throw_cooldown after the previous one — only
	# _on_animation_finished's own wait normally enforces that, and it can't
	# do so for a fresh enter().
	var remaining_sec := throw_cooldown - (Time.get_ticks_msec() - _last_attack_msec) / 1000.0
	if remaining_sec > 0.0:
		await get_tree().create_timer(remaining_sec).timeout
		if not is_active:
			return
	_start_attack()


func exit() -> void:
	if is_instance_valid(anim_player) and anim_player.animation_finished.is_connected(_on_animation_finished):
		anim_player.animation_finished.disconnect(_on_animation_finished)
	if is_instance_valid(anim_player):
		anim_player.active = false
	if is_instance_valid(anim_tree):
		anim_tree.active = true
	if is_instance_valid(hurt_trigger):
		hurt_trigger.disabled = false


func physics_update(_delta: float) -> void:
	if is_instance_valid(guide):
		guide.set_target(get_target_position())
		guide.face_target()


func get_aim_position() -> Vector3:
	return get_target_position() + Vector3.UP * aim_height_offset


func is_target_in_range() -> bool:
	if not is_instance_valid(root):
		return false
	return root.global_position.distance_to(get_target_position()) <= max_range


func _on_animation_finished(anim_name: StringName) -> void:
	if not _is_attack_animation(anim_name):
		return
	await get_tree().create_timer(throw_cooldown).timeout
	if not is_active:
		return
	if is_instance_valid(health) and health.dead:
		return
	if not can_see_target() or not is_target_in_range():
		transition_to(return_to_chase_state)
		print("Target too far, starting chase")
		return
	_start_attack()


func _start_attack() -> void:
	if not is_instance_valid(anim_player):
		return
	_last_attack_msec = Time.get_ticks_msec()
	anim_player.play(_get_attack_animation())


func _get_attack_animation() -> StringName:
	return attack_anim


func _is_attack_animation(anim_name: StringName) -> bool:
	return anim_name == attack_anim
