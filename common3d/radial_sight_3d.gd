extends Node3D
class_name RadialSight3D

signal found_target(new_target: Node3D)
signal lost_target

@export var radius := 20.0
@export var lose_distance := 40.0
@export var can_lose_target := true
@export var target_update_frequency := 0.2
@export_flags_3d_physics var target_collision_mask := 1
@export_flags_3d_physics var ray_collision_mask := 1

@export var group_whitelist: Array[String] = []

var area: Area3D
var collision_shape: CollisionShape3D
var ray: RayCast3D
var update_timer: Timer

var target: Node3D
var target_position: Vector3:
	get:
		if does_see_target():
			target_position = target.global_position
		return target_position

func _ready() -> void:
	target_position = global_position
	
	area = Area3D.new()
	add_child(area)
	area.collision_layer = 0
	area.collision_mask = target_collision_mask
	
	collision_shape = CollisionShape3D.new()
	area.add_child(collision_shape)
	var shape := SphereShape3D.new()
	shape.radius = radius
	collision_shape.shape = shape
	
	ray = RayCast3D.new()
	add_child(ray)
	ray.target_position = Vector3.FORWARD * radius
	
	update_timer = Timer.new()
	add_child(update_timer)
	update_timer.wait_time = target_update_frequency
	update_timer.start()
	update_timer.timeout.connect(update_target)

func target_is_lost() -> bool:
	return can_lose_target and global_position.distance_to(target.global_position) >= lose_distance

func update_target() -> void:
	if does_see_target() and not target_is_lost():
		return
	
	var nodes_in_area: Array[Node3D] = []
	nodes_in_area.append_array(area.get_overlapping_areas())
	nodes_in_area.append_array(area.get_overlapping_bodies())
	
	if target != null:
		lost_target.emit()
	
	target = null
	nodes_in_area = nodes_in_area.filter(
		func(node: Node3D) -> bool:
			if not is_instance_valid(node):
				return false
			for group in group_whitelist:
				if node.is_in_group(group):
					return true
			return false
	)
	nodes_in_area = Util.distance_sort_3d(nodes_in_area, global_position)
	for node in nodes_in_area:
		if node == null:
			continue
		ray.look_at(node.global_position)
		if ray.get_collider() == node:
			target = node
			found_target.emit(target)
			return

func does_see_target() -> bool:
	return is_instance_valid(target) and target != null
