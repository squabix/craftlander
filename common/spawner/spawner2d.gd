class_name Spawner2D
extends Node2D

signal spawned(node2d: Node2D)

enum TransformMode { SELF, PARENT, DEFAULT }
enum PositionRangeSampleMode { INSIDE, OUTSIDE }

@export var ignore_pausing := false
@export var child_of_root := true
@export var default_scene: PackedScene
@export var default_parent: Node
@export var spawn_on_parent_queue_free := false

@export_group("Transform")
@export var default_position := Vector2(0.0, 0.0)
@export_range(-360.0, 360.0) var default_rotation_degrees := 0.0

#@export var position_range_node: PositionRangeNode2D
var all_spawned_nodes: Array[Node2D]


func spawn(scene: PackedScene = null, parent: Node = default_parent) -> Node:
	if scene == null or not scene.can_instantiate():
		scene = get_scene()

	if parent == null:
		return null
	if scene == null:
		return null

	var instance: Node2D = scene.instantiate()
	add_instance(instance)
	spawned.emit(instance)
	initialize_instance(instance)

	return instance


func get_scene() -> PackedScene:
	return default_scene


func add_instance(instance: Node2D) -> void:
	if instance == null:
		return

	if not all_spawned_nodes.has(instance):
		all_spawned_nodes.append(instance)

	if instance.get_parent() != default_parent:
		default_parent.add_child(instance)

	#if position_range_node != null:
	#instance.global_position = position_range_node.sample()
	#else:
	instance.global_position = default_position
	instance.global_rotation_degrees = default_rotation_degrees


func initialize_instance(_instance: Node2D) -> void:
	# Override this method to initialize the spawned instance
	pass
