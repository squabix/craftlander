class_name GuardState
extends SequenceState

const SPARK_HEIGHT := 0.5
const PUSH_LIFT := 0.3

@export var next_state := &"Chasing"
@export var hurtbox: Hurtbox3D
@export var block_player: AudioStreamPlayer3D

@export_group("Timing")
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var duration := 2.0
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var raise_time := 0.12

@export_group("Animation", "animation")
@export var animation_blend_parameter := &"parameters/GuardBlend/blend_amount"
@export var animation_counter_one_shot := &"AttackOneShot"

@export_group("Block", "block")
@export var block_color := Color(1.0, 0.85, 0.5)
@export var block_knockback := 8.0
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var block_knockback_range := 3.0

var enemy: Enemy3D:
	get:
		return root as Enemy3D

var _blend_tween: Tween


func run() -> void:
	raise()
	if not await hold():
		return

	lower()
	counter()
	go_to(next_state)


func exit() -> void:
	if hurtbox.was_blocked.is_connected(block):
		hurtbox.was_blocked.disconnect(block)
	enemy.get_health().invulnerable = false
	lower()


func raise() -> void:
	enemy.get_health().invulnerable = true
	if not hurtbox.was_blocked.is_connected(block):
		hurtbox.was_blocked.connect(block)
	tween_blend(1.0)


func lower() -> void:
	tween_blend(0.0)


func hold() -> bool:
	var elapsed := 0.0
	while elapsed < duration:
		await get_tree().physics_frame
		if not is_alive():
			return false

		var delta := get_physics_process_delta_time()
		elapsed += delta
		face_target(delta)

	return true


func face_target(delta: float) -> void:
	var target := enemy.get_target()
	if is_instance_valid(target):
		enemy.aim_toward(target.global_position, delta, false)


func counter() -> void:
	enemy.get_health().invulnerable = false
	if is_instance_valid(enemy.anim_tree):
		enemy.anim_tree.set("parameters/%s/request" % animation_counter_one_shot, AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)


func block(damage: Damage, direction: Vector3) -> void:
	spark(direction)
	var attacker := damage.source as Entity3D
	if is_instance_valid(attacker):
		push_back(attacker)


func spark(direction: Vector3) -> void:
	if is_instance_valid(block_player):
		block_player.play()
	EnemyVfx.impact(Spawner3D.root, hurtbox.global_position + Vector3.UP * SPARK_HEIGHT, block_color, -direction if direction != Vector3.ZERO else Vector3.UP)


func push_back(attacker: Entity3D) -> void:
	var push := attacker.global_position - enemy.global_position
	push.y = 0.0
	if push.length() <= block_knockback_range:
		attacker.add_impulse((push.normalized() + Vector3.UP * PUSH_LIFT).normalized() * block_knockback)


func tween_blend(to: float) -> void:
	if not is_instance_valid(enemy.anim_tree):
		return
	if _blend_tween != null:
		_blend_tween.kill()

	_blend_tween = create_tween()
	_blend_tween.tween_property(enemy.anim_tree, NodePath(animation_blend_parameter), to, raise_time)
