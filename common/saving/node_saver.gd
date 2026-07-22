class_name NodeSaver
extends Node

enum OffloadMode {
	FREE,
	IGNORE_MEMBERS,
	DISABLED,
}

static var save: Save
static var scene_root: Node
static var offload_on_free_enabled := true
static var all: Dictionary[Node, NodeSaver] = { }

@export var save_mode := NodeSave.Mode.STATIC_SCENE
@export var saver_id: StringName:
	get:
		if saver_id.is_empty():
			return StringName(target.name if is_instance_valid(target) else name)
		return saver_id
@export var saved_properties: Dictionary[StringName, bool]
@export var load_methods: Array[StringName]
@export var custom_target: Node

@export_group("Loading")
@export var loaded := false
@export var reload_when_loaded := false
@export var save_when_unloaded := false

@export_group("Offloading")
@export var offloaded := false
@export var offload_mode: OffloadMode = OffloadMode.FREE
@export var offload_on_free := true

var target: Node
var dynamic_uuid := &""


static func get_scene_context() -> String:
	return scene_root.scene_file_path if is_instance_valid(scene_root) else ""


static func save_all() -> void:
	filter_all()
	for saver in all.values() as Array[NodeSaver]:
		saver.save_properties()


static func load_all() -> void:
	filter_all()
	for saver in all.values() as Array[NodeSaver]:
		saver.load_properties()


static func filter_all() -> void:
	var filtered: Dictionary[Node, NodeSaver] = { }
	for node in all:
		if not is_instance_valid(node):
			continue
		var saver := all[node]
		if not is_instance_valid(saver):
			continue
		filtered[node] = saver
	all = filtered


static func get_root_path(node: Node) -> NodePath:
	if not is_instance_valid(node):
		printerr("Cannot get root path from invalid node: %s" % node)
		return NodePath()
	return (
			node.get_path() if not is_instance_valid(scene_root) or scene_root == node
			else scene_root.get_path_to(node)
	)


func _ready() -> void:
	target = custom_target if is_instance_valid(custom_target) else get_parent()
	all[target] = self


func _exit_tree() -> void:
	_free_offload()
	all.erase(target)


func offload() -> void:
	offloaded = true


func onload() -> void:
	offloaded = false


func get_property_data() -> Dictionary[StringName, Variant]:
	if not is_instance_valid(target):
		printerr("%s cannot get property data from invalid target: %s" % target)
		return { }

	var property_data: Dictionary[StringName, Variant] = { }
	for property in saved_properties:
		if saved_properties[property] == false:
			continue # Property is disabled
		if not property in target:
			printerr("%s cannot get nonexistant property '%s' from %s" % [self, property, target])
			continue
		property_data[property] = target.get(property)
	return property_data


func set_property_data(property_data: Dictionary[StringName, Variant]) -> void:
	if not is_instance_valid(target):
		printerr("%s cannot set property data to invalid target: %s" % target)
		return
	for property: StringName in property_data:
		var value: Variant = property_data[property]
		if not property in saved_properties:
			printerr("%s cannot set unsaved property '%s' to '%s' in %s" % [self, property, value, target])
			continue
		if saved_properties[property] == false:
			continue # Property is disabled
		if not property in target:
			printerr("%s cannot set nonexistant property '%s' to '%s' in %s" % [self, property, property_data[property], target])
			continue
		target.set(property, value)


func save_properties() -> void:
	var index := find_index()
	if not loaded and not save_when_unloaded and index != -1:
		return

	if save == null:
		printerr("%s cannot save properties with null save")
		return

	if save_mode == NodeSave.Mode.DYNAMIC and dynamic_uuid.is_empty():
		dynamic_uuid = get_uuid()

	var property_data: Dictionary[StringName, Variant] = { }
	var skip_properties := offloaded and offload_mode == OffloadMode.IGNORE_MEMBERS

	if not skip_properties:
		property_data = get_property_data()
		# Only block saving empty data if it's a standard static/global node and NOT offloaded
		if property_data.is_empty() and save_mode != NodeSave.Mode.DYNAMIC and not offloaded:
			return

	var node_save := NodeSave.new(saver_id, save_mode, get_scene_context(), property_data)
	node_save.offloaded = offloaded

	match save_mode:
		NodeSave.Mode.DYNAMIC:
			node_save.make_dynamic(dynamic_uuid, target)
		NodeSave.Mode.STATIC_SCENE:
			node_save.make_static_scene(get_root_path(self))
		NodeSave.Mode.GLOBAL:
			node_save.make_global()

	if index != -1:
		save.node_properties[index] = node_save
	else:
		save.node_properties.append(node_save)


func load_properties() -> void:
	if loaded and not reload_when_loaded:
		return

	if save == null:
		printerr("%s cannot load properties with null save")
		return

	var index := find_index()
	if index == -1:
		return

	var node_save := save.node_properties[index]

	offloaded = node_save.offloaded
	if node_save.offloaded:
		match offload_mode:
			OffloadMode.FREE:
				if is_instance_valid(target):
					target.queue_free()
				return
			OffloadMode.IGNORE_MEMBERS:
				return
			OffloadMode.DISABLED:
				pass # Load properties normally

	set_property_data(node_save.properties)
	call_load_callables()
	loaded = true


func call_load_callables() -> void:
	if not is_instance_valid(target):
		printerr("%s cannot call load methods (%s) on invalid target: %s" % [self, load_methods, target])
		return
	for method_name in load_methods:
		if not target.has_method(method_name):
			printerr("%s cannot call nonexistant method (%s) on %s" % [self, method_name, target])
			return
		target.call(method_name)


func get_uuid() -> StringName:
	return StringName("%s_%s" % [str(ResourceUID.create_id()), str(randi())])


func find_index() -> int:
	var current_scene := get_scene_context()

	for i in range(save.node_properties.size()):
		var node_save := save.node_properties[i]
		if node_save.mode != save_mode or node_save.mode == NodeSave.Mode.NONE:
			continue

		if (
				(
						save_mode == NodeSave.Mode.DYNAMIC
						and node_save.dynamic_uuid == dynamic_uuid
						and not dynamic_uuid.is_empty()
				)
				or (
						save_mode == NodeSave.Mode.STATIC_SCENE
						and node_save.saver_id == saver_id
						and node_save.scene_context == current_scene
						and node_save.relative_path == get_root_path(self)
				)
				or (
						save_mode == NodeSave.Mode.GLOBAL
						and node_save.saver_id == saver_id
				)
		):
			return i

	return -1


func _free_offload() -> bool:
	if not offload_on_free or not offload_on_free_enabled:
		return false

	if not is_instance_valid(scene_root):
		printerr("%s cannot free offload with invalid scene root: %s" % [self, scene_root])
		return false

	if not (is_instance_valid(target) and target.is_queued_for_deletion()):
		return false

	# Check if scene root or scene root ancestors are being freed
	var check := scene_root
	while is_instance_valid(check):
		if check.is_queued_for_deletion():
			return false
		check = check.get_parent()

	offload()
	save_properties()
	return true
