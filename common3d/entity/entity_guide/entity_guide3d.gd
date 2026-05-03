extends Node
class_name EntityGuide3D

@export var entity: Entity3D
@export_range(0.0, 1.0) var face_interpolation: float = 1.0

var target_position: Vector3

func set_target(to: Vector3) -> void:
	target_position = to

func get_direction() -> Vector3:
	return Vector3.ZERO

func face_target() -> void:
	pass

func get_distance_to_target() -> float:
	return 0.0

func move_forward() -> void:
	entity.move_forward()

#func accel_toward(target: Vector3, accelerator: Accelerator) -> void:
	#if not is_instance_valid(accelerator):
		#return
	#var direction: Vector3 = get_direction(target)
	#var velocity: Vector3 = accelerator.accel3d(
		#entity.velocity,
		#Util.flatten_vec3(direction)
	#)
	#entity.get_velocity_state().set_reactive(velocity)
