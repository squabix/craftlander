extends Node
class_name RigidBodyVelocityLimiter3D

@export var enabled := true
@export var limit: float = 5.0
@export var axes: BoolVector3

func _process(delta: float) -> void:
	if not enabled:
		return
	var parent := get_parent()
	if not parent is RigidBody3D:
		Util.safe_free(self)
		return
	var original_velocity: Vector3 = parent.linear_velocity
	if original_velocity.length() > limit:
		parent.linear_velocity = BoolVector3.replace(
			original_velocity,
			original_velocity.limit_length(limit),
			axes
		)
