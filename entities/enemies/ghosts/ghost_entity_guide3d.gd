class_name GhostEntityGuide3D
extends LinearEntityGuide3D

@export var hoverer: Hoverer3D

@export_group("Steering", "steer")
@export var steer_separation_enabled := true
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var steer_separation_radius := 2.5
@export var steer_separation_weight := 1.5
@export var steer_separation_group: StringName = &"ghosts"

@export_group("Align", "align")
@export var align_enabled := true
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var align_range := 8.0
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var align_full_range := 3.5

var slot_offset := Vector3.ZERO


func _init() -> void:
	face_interpolation = 0.1
	ignore_y_distance = true


func _physics_process(_delta: float) -> void:
	if align_enabled and is_instance_valid(hoverer):
		var weight := clampf(inverse_lerp(align_range, align_full_range, get_distance_to_target()), 0.0, 1.0)
		hoverer.set_height_bias(target_position.y, weight)


func face_target() -> void:
	if not is_instance_valid(entity):
		return
	
	var heading := get_heading() * Vector3(1.0, 0.0, 1.0)
	if heading.length_squared() < 0.0001:
		return
	
	Util.lerp_look_at_3d(entity, entity.global_position + heading, face_interpolation)


func face_true_target() -> void:
	super.face_target()


func get_heading() -> Vector3:
	var to_slot := Vector3(
		target_position.x + slot_offset.x,
		entity.global_position.y,
		target_position.z + slot_offset.z,
	) - entity.global_position
	to_slot.y = 0.0
	return to_slot.normalized() + get_separation() * steer_separation_weight


func get_separation() -> Vector3:
	var push := Vector3.ZERO
	if not steer_separation_enabled:
		return push
	
	for other in get_tree().get_nodes_in_group(steer_separation_group):
		if other == entity or not other is Node3D:
			continue
		
		var away: Vector3 = entity.global_position - other.global_position
		away.y = 0.0
		
		var distance := away.length()
		if distance > 0.001 and distance < steer_separation_radius:
			push += away / distance * (1.0 - distance / steer_separation_radius)
			
	return push
