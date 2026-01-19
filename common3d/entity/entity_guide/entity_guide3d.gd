extends Node
class_name EntityGuide3D

@export var entity: Entity3D

var target_position: Vector3

func set_target(to: Vector3) -> void:
	target_position = to

func get_direction() -> Vector3:
	return Vector3.ZERO

#func accel_toward(target: Vector3, accelerator: Accelerator) -> void:
	#if not is_instance_valid(accelerator):
		#return
	#var direction: Vector3 = get_direction(target)
	#var velocity: Vector3 = accelerator.accel3d(
		#entity.velocity,
		#Util.flatten_vec3(direction)
	#)
	#entity.get_velocity_state().set_reactive(velocity)
