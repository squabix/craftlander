class_name MultiSpawner3D
extends Node3D

enum SelectMode { ALL, RANDOM, CUSTOM }

@export var sub_spawners: Dictionary[Spawner3D, bool]
@export var do_duplicate_passed_instance := true

@export_group("Selection", "select")
@export var select_mode: SelectMode
@export var select_index_override := -1

@export_group("Default Parent Override")
@export var do_override_default_parent := false
@export var default_parent_mode := Spawner3D.DefaultParentMode.ROOT
@export var custom_default_parent_override: Node
@export var default_parent_override_ancestor_level := 1

var spawned_instances: Array[Node3D]


func get_enabled_spawners() -> Array[Spawner3D]:
	return sub_spawners.keys().filter(is_enabled)


func is_enabled(spawner: Spawner3D) -> bool:
	return is_instance_valid(spawner) and sub_spawners.get(spawner, false)


func select_spawners() -> Array[Spawner3D]:
	var enabled_spawners := get_enabled_spawners()
	if enabled_spawners.is_empty():
		return []
	
	if select_index_override > -1 and select_index_override < enabled_spawners.size():
		return [enabled_spawners[select_index_override]]

	match select_mode:
		SelectMode.ALL:
			return enabled_spawners
		SelectMode.CUSTOM:
			return select_custom_spawners(enabled_spawners)
		SelectMode.RANDOM:
			return [enabled_spawners.pick_random()]
	
	return []


func get_default_parent() -> Node:
	if is_instance_valid(custom_default_parent_override):
		return custom_default_parent_override
	match default_parent_mode:
		Spawner3D.DefaultParentMode.ROOT:
			return Spawner3D.root
		Spawner3D.DefaultParentMode.SELF:
			return self
		Spawner3D.DefaultParentMode.ANCESTOR:
			return Util.get_ancestor(self, default_parent_override_ancestor_level)
	return null


func enable_spawner(spawner: Spawner3D) -> void:
	sub_spawners[spawner] = true


func disable_spawner(spawner: Spawner3D) -> void:
	sub_spawners[spawner] = false


func spawn(instance: Node3D = null, parent: Node = null) -> Array[Node3D]:
	var instances: Array[Node3D] = []
	for spawner in select_spawners():
		var passable_instance := spawner.spawn(get_passable_instance(instance))
		instances.append(spawner.spawn(passable_instance, parent))
		_initialize_instance(passable_instance)
	spawned_instances.append_array(instances.filter(is_instance_valid))
	return instances


func _initialize_instance(_instance: Node3D) -> void:
	pass


func get_passable_instance(base_instance: Node3D) -> Node3D:
	if not is_instance_valid(base_instance):
		return null
	if do_duplicate_passed_instance:
		return base_instance.duplicate()
	return base_instance


func select_custom_spawners(enabled_spawners: Array[Spawner3D]) -> Array[Spawner3D]:
	return enabled_spawners
