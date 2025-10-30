extends Node3D
class_name LagNode3D

@export_range(0.0, 1.0) var position_speed: float = 1.0
@export_range(0.0, 1.0) var rotation_speed: float = 1.0
@export var max_position_distance: float
@export var max_rotation_distance: float

var last_global_position: Vector3
var last_global_rotation: Vector3

func _process(_delta: float) -> void:
	var parent_position: Vector3 = get_parent().global_position
	global_position = last_global_position.lerp(
		parent_position,
		position_speed
	).move_toward(
		parent_position,
		max(
			global_position.distance_to(parent_position) - max_position_distance,
			0.0
		)
	)
	var parent_rotation: Vector3 = get_parent().global_rotation
	global_rotation = last_global_rotation.lerp(
		parent_rotation,
		rotation_speed
	).move_toward(
		parent_rotation,
		max(
			global_rotation.distance_to(parent_rotation) - max_rotation_distance,
			0.0
		)
	)
