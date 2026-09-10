class_name SnailSpittingState
extends RangedAttackState

@export var spawner: ProjectileSpawner3D


func _release() -> void:
	if not is_instance_valid(spawner):
		return
	spawner.look_at(get_aim_position(), Vector3.UP)
	spawner.spawn()
