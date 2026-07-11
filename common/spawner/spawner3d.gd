class_name Spawner3D
extends Node3D

signal spawned(node3d: Node3D)

enum TransformMode { SELF, PARENT, DEFAULT }
enum DefaultParentMode { ROOT, SELF, CUSTOM }

@export var default_scene: PackedScene
@export var ignore_pausing: bool
@export var spawn_on_exit_tree := false

@export_group("Default Parent")
@export var default_parent_mode := DefaultParentMode.ROOT
@export var custom_default_parent: Node

@export_group("Transform")
@export var position_mode: TransformMode = TransformMode.PARENT
@export var rotation_mode: TransformMode = TransformMode.PARENT
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var default_position: Vector3
@export_custom(PROPERTY_HINT_NONE, "suffix:°") var default_rotation_degrees: Vector3

@export_group("Timing")
@export var spawn_frequency: float
@export var spawn_time_variation: float
@export var autostart_timer: bool

var has_started_timer: bool
var root: Node


static func spawn_at(spawn_position: Vector3, spawn_rotation_degrees: Vector3, scene: PackedScene, parent: Node, initializer: Callable = Callable()) -> Node3D:
	if scene == null or not scene.can_instantiate():
		return

	if parent == null:
		return

	var instance: Node3D = scene.instantiate()
	parent.add_child(instance)
	instance.global_position = spawn_position
	instance.global_rotation_degrees = spawn_rotation_degrees
	if not initializer.is_null():
		initializer.call(instance)

	return instance


func _ready() -> void:
	root = get_tree().root
	if spawn_on_exit_tree:
		tree_exiting.connect(spawn)
		assert(
				default_parent_mode != DefaultParentMode.SELF,
				"Default parent mode of %s is set to self, so cannot spawn %s on exit tree" % [self, default_scene]
		)


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
	match position_mode:
		TransformMode.PARENT:
			if is_instance_valid(parent) and parent is Node3D:
				return parent.global_rotation_degrees
		TransformMode.DEFAULT:
			return default_rotation_degrees
		TransformMode.SELF:
			return global_rotation_degrees
	return global_rotation_degrees


func initialize_instance(_instance: Node3D) -> void:
	pass


func get_scene() -> PackedScene:
	return default_scene


func spawn(custom_scene: PackedScene = null, parent: Node = null) -> Node3D:
	if not is_instance_valid(parent):
		parent = get_default_parent()
		if not is_instance_valid(parent):
			return
	
	var scene := custom_scene if custom_scene != null else get_scene()

	var spawn_position: Vector3 = get_spawn_position(parent)
	var spawn_rotation_degrees: Vector3 = get_spawn_rotation_degrees(parent)

	var instance: Node3D = Spawner3D.spawn_at(
		spawn_position, # Spawn position
		spawn_rotation_degrees, # Spawn rotation
		scene, # Scene
		parent, # Parent
		initialize_instance, # Initializer
	)
	spawned.emit(instance)
	return instance
