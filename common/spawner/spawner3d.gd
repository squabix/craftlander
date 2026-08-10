class_name Spawner3D
extends Node3D

signal spawned(node3d: Node3D)

enum TransformMode { SELF, PARENT, DEFAULT }
enum DefaultParentMode { ROOT, SELF, CUSTOM }

static var root: Node:
	get:
		if not is_instance_valid(root):
			root = (Engine.get_main_loop() as SceneTree).root
		return root

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


func spawn(instance: Node3D=null, parent: Node = null) -> Node3D:
	if is_queued_for_deletion():
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
	
	if parent.is_queued_for_deletion():
		instance.queue_free()
		return null
	
	parent.add_child(instance)
	instance.global_position = get_spawn_position(parent)
	instance.global_rotation_degrees = get_spawn_rotation_degrees(parent)

	initialize_instance(instance)
	spawned.emit(instance)
	return instance
