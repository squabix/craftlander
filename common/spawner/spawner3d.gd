extends Node3D
class_name Spawner3D

signal spawned(node3d: Node3D)

enum TransformMode {SELF, PARENT, DEFAULT}

@export var ignore_pausing: bool
@export var child_of_root: bool = true

@export var default_parent: Node

@export_group("Transform")
@export var position_mode: TransformMode = TransformMode.PARENT
@export var rotation_mode: TransformMode = TransformMode.PARENT
@export var default_position: Vector3
@export var default_rotation_degrees: Vector3

@export_group("Timing")
@export var spawn_frequency: float
@export var spawn_time_variation: float
@export var autostart_timer: bool

var has_started_timer: bool

func _ready() -> void:
	if child_of_root:
		default_parent = get_tree().root
	else:
		if default_parent == null:
			default_parent = self

func get_spawn_position(parent: Node) -> Vector3:
	match position_mode:
		TransformMode.PARENT:
			if child_of_root:
				pass
			elif not parent is Node3D:
				pass
			else:
				return parent.global_position
		TransformMode.DEFAULT:
			return default_position
		TransformMode.SELF:
			return global_position
	
	return global_position

func get_spawn_rotation_degrees(parent: Node) -> Vector3:
	match position_mode:
		TransformMode.PARENT:
			if child_of_root:
				pass
			elif not parent is Node2D:
				pass
			else:
				return parent.global_rotation_degrees
		TransformMode.DEFAULT:
			return default_rotation_degrees
		TransformMode.SELF:
			return global_rotation_degrees
	return global_rotation_degrees

func initialize_instance(_instance: Node3D) -> void:
	pass

func get_scene() -> PackedScene:
	return null

func spawn(custom_scene: PackedScene = null, custom_parent: Node=null) -> Node3D:
	var parent := custom_parent if custom_parent != null else (get_tree().root if child_of_root else default_parent)
	var scene := custom_scene if custom_scene != null else get_scene()
	
	var spawn_position: Vector3 = get_spawn_position(parent)
	var spawn_rotation_degrees: Vector3 = get_spawn_rotation_degrees(parent)
	
	var instance: Node3D = Spawner3D.spawn_at(
		spawn_position,				# Spawn position
		spawn_rotation_degrees,		# Spawn rotation
		scene,						# Scene
		parent,						# Parent
		initialize_instance			# Initializer
	)
	spawned.emit(instance)
	return instance

static func spawn_at(spawn_position: Vector3, spawn_rotation_degrees: Vector3, scene: PackedScene, parent: Node, initializer: Callable=Callable()) -> Node3D:
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
