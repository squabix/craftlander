class_name FollowNode3D
extends Node3D

@export var target: Node3D
@export var min_approach_distance: float = 0.0
@export var min_retreat_distance: float = 0.0
@export var max_approach_distance: float = 0.0
@export_range(0.0, 1.0) var lerp_weight: float = 1.0

var direction: Vector3

func _process(_delta: float) -> void:
	update_direction()

func update_target(to: Node3D) -> void:
	if to == null or not is_instance_valid(to):
		if not is_instance_valid(target):
			target = null
	target = to

func get_direction() -> Vector3:
	return direction

func get_distance() -> float:
	if is_instance_valid(target):
		return global_position.distance_to(target.global_position)
	return INF

func retreat() -> void:
	direction = direction.lerp(-global_position.direction_to(target.global_position), lerp_weight)

func idle() -> void:
	direction = direction.lerp(Vector3.ZERO, lerp_weight)

func approach() -> void:
	direction = direction.lerp(global_position.direction_to(target.global_position), lerp_weight)

func has_min_approach_distance() -> bool: return min_approach_distance > 0.0
func has_max_approach_distance() -> bool: return max_approach_distance > 0.0

func update_direction() -> void:
	if target == null:
		idle()
		return
	
	var distance: float = get_distance()
	
	if has_min_approach_distance() and distance < min_approach_distance:
		if distance < min_retreat_distance:
			retreat()
		else:
			idle()
	elif not has_max_approach_distance() or distance < max_approach_distance:
		approach()
	
