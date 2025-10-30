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

func update_direction() -> void:
	if target == null:
		direction = direction.lerp(Vector3.ZERO, lerp_weight)
		return
	
	var distance: float = get_distance()
	var raw_direction: Vector3
	
	if min_approach_distance > 0.0 and distance < min_approach_distance:
		
		# Idle
		if distance < min_retreat_distance:
			raw_direction = -global_position.direction_to(target.global_position)
		
		# Retreat
		else:
			raw_direction = Vector3.ZERO
	
	# Approach
	elif (max_approach_distance > 0.0 and distance < max_approach_distance) or max_approach_distance == 0.0:
			raw_direction = global_position.direction_to(target.global_position)
	
	direction = direction.lerp(raw_direction, lerp_weight)
