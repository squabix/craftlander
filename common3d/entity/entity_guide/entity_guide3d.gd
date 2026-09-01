class_name EntityGuide3D
extends Node

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


func move_backward() -> void:
	entity.move_backward()
