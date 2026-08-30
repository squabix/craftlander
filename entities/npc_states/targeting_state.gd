class_name TargetingState
extends State

@export var guide: EntityGuide3D
@export var sight: RadialSight3D
@export var default_target: Node3D


func can_see_target() -> bool:
	if sight == null:
		return false
	return sight.does_see_target()


func get_target_position() -> Vector3:
	if sight != null:
		return sight.target_position
	if is_instance_valid(default_target):
		return default_target.global_position
	if is_instance_valid(root):
		return root.global_position
	return Vector3.ZERO
