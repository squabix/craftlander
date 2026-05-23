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

func add_area() -> void:
	area = Area3D.new()
	add_child(area)
	area.collision_layer = 0
	area.collision_mask = target_collision_mask

func add_collision() -> void:
	collision_shape = CollisionShape3D.new()
	area.add_child(collision_shape)
	var shape := SphereShape3D.new()
	shape.radius = radius
	collision_shape.shape = shape

func add_ray() -> void:
	ray = RayCast3D.new()
	add_child(ray)
	ray.target_position = Vector3.FORWARD * radius

func add_timer() -> void:
	update_timer = Timer.new()
	add_child(update_timer)
	update_timer.wait_time = target_update_frequency
	update_timer.start()
	update_timer.timeout.connect(update_target)

func _ready() -> void:
	target_position = global_position
	add_area()
	add_collision()
	add_ray()
	add_timer()

func target_is_lost() -> bool:
	return can_lose_target and global_position.distance_to(target.global_position) >= lose_distance

func set_target(to: Node3D) -> void:
	target = to
	found_target.emit(target)

func is_targetable(node: Node3D) -> bool:
	if not is_instance_valid(node):
		return false
	for group in group_whitelist:
		if node.is_in_group(group):
			return true
	return false

func get_targetable_nodes() -> Array[Node3D]:
	var nodes_in_area: Array[Node3D] = area.get_overlapping_areas() + area.get_overlapping_bodies()
	return Util.distance_sort_3d(nodes_in_area.filter(is_targetable), global_position)

func is_ray_reachable(node: Node3D) -> bool:
	ray.look_at(node.global_position)
	ray.force_raycast_update()
	return ray.get_collider() == node

func lose_target() -> void:
	if target == null:
		return
	lost_target.emit()
	target = null

func update_target() -> void:
	if does_see_target() and not target_is_lost():
		return
	
	lose_target()
	
	var sorted_targetable_nodes := Util.distance_sort_3d(get_targetable_nodes(), global_position)
	for node in sorted_targetable_nodes:
		if is_ray_reachable(node):
			set_target(node)
			return

func does_see_target() -> bool:
	return is_instance_valid(target) and target != null
