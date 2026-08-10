class_name Spawner3D
extends Node3D

signal spawned(node3d: Node3D)

enum TransformMode { SELF, PARENT, DEFAULT }
enum DefaultParentMode { ROOT, SELF, CUSTOM }

static var root: Node:
	get:
		if not is_instance_valid(root):
			root = Util.get_tree().root
		return root

@export var defer := true
@export var ignore_pausing: bool
@export var spawn_on_exit_tree := false

@export_group("Default Parent")
@export var default_parent_mode := DefaultParentMode.ROOT
@export var custom_default_parent: Node

@export_group("Transform")
@export var position_mode := TransformMode.SELF
@export var rotation_mode := TransformMode.SELF
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var default_position: Vector3
@export_custom(PROPERTY_HINT_NONE, "suffix:°") var default_rotation_degrees: Vector3

@export_group("Timing")
@export var spawn_frequency: float
@export var spawn_time_variation: float
@export var autostart_timer: bool

var has_started_timer: bool


static func _transform(node: Node3D, node_position: Vector3, node_rotation_degrees: Vector3) -> void:
	await Util.get_tree().process_frame
	if not is_instance_valid(node):
		push_error("Cannot spawn transform invalid node")
		return
	node.global_position = node_position
	node.global_rotation_degrees = node_rotation_degrees


func _ready() -> void:
	if spawn_on_exit_tree:
		tree_exiting.connect(func(): spawn())
		if default_parent_mode == DefaultParentMode.SELF:
			Util.node_error("Default parent mode of %s is set to SELF and spawning on exit tree; updating mode to ROOT", self)
			default_parent_mode = DefaultParentMode.ROOT


func get_default_parent() -> Node:
	match default_parent_mode:
		DefaultParentMode.ROOT:
			return root
		DefaultParentMode.SELF:
			return self
		DefaultParentMode.CUSTOM:
			return custom_default_parent
	return null


func get_spawn_position(parent: Node) -> Vector3:
	match position_mode:
		TransformMode.PARENT:
			if is_instance_valid(parent) and parent is Node3D:
				return parent.global_position
		TransformMode.DEFAULT:
			return default_position
		TransformMode.SELF:
			return global_position

	return global_position


func get_spawn_rotation_degrees(parent: Node) -> Vector3:
	match rotation_mode:
		TransformMode.PARENT:
			if is_instance_valid(parent) and parent is Node3D:
				return parent.global_rotation_degrees
		TransformMode.DEFAULT:
			return default_rotation_degrees
		TransformMode.SELF:
			return global_rotation_degrees
	return global_rotation_degrees


func create_instance() -> Node3D:
	return null


func initialize_instance(_instance: Node3D) -> void:
	pass


func spawn(instance: Node3D = null, parent: Node = null) -> Node3D:
	if is_queued_for_deletion() or not is_inside_tree():
		return null

	if instance == null:
		instance = create_instance()
		if instance == null:
			Util.node_error("%s cannot spawn null instance", self)
			return null

	if not is_instance_valid(parent):
		parent = get_default_parent()
		if not is_instance_valid(parent):
			instance.queue_free()
			return null

	if parent.is_queued_for_deletion() or not parent.is_inside_tree():
		instance.queue_free()
		return null
	var instance_position := get_spawn_position(parent)
	var instance_rotation_degrees := get_spawn_rotation_degrees(parent)

	if defer:
		parent.add_child.call_deferred(instance)
		_transform(instance, instance_position, instance_rotation_degrees)
	else:
		parent.add_child(instance)
		instance.global_position = instance_position
		instance.global_rotation_degrees = instance_rotation_degrees

	_call_initializer(instance)
	spawned.emit(instance)
	return instance


func _call_initializer(instance: Node3D) -> void:
	if defer:
		initialize_instance.call_deferred(instance)
	else:
		initialize_instance(instance)
