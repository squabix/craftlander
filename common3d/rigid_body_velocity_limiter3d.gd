extends Node
class_name RigidBodyVelocityLimiter3D

@export var limit: float = 5.0

func _process(delta: float) -> void:
	if not get_parent() is RigidBody3D:
		Util.safe_free(self)
		return
	if get_parent().linear_velocity.length() > limit:
		get_parent().linear_velocity = get_parent().linear_velocity.limit_length(limit)
