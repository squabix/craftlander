class_name NodeSaver
extends Node

enum OffloadMode {
	FREE,
	IGNORE_PROPERTIES,
	DISABLED,
}

static var save: Save
static var scene_root: Node
static var all: Dictionary[Node, NodeSaver] = { }

@export var save_mode := NodeSave.Mode.STATIC_SCENE
@export var saver_id: StringName:
	get:
		if saver_id.is_empty():
			return StringName(target.name if is_instance_valid(target) else name)
		return saver_id
@export var saved_properties: Array[StringName]
@export var custom_target: Node

@export_group("Offloading", "offload")
@export var offload_mode: OffloadMode = OffloadMode.FREE
@export var offload_on_free := true

var target: Node
var dynamic_uuid := &""
var _is_offloaded: bool = false


static func get_scene_context() -> String:
	if not is_instance_valid(scene_root):
		return ""
	return scene_root.scene_file_path


static func save_all() -> void:
	filter_all()
	for saver in all.values():
		saver.save_properties()


static func load_all() -> void:
	filter_all()
	for saver in all.values():
		saver.load_properties()


static func filter_all() -> void:
	var filtered: Dictionary[Node, NodeSaver] = { }
	for node in all:
		if is_instance_valid(node) and is_instance_valid(all[node]):
			filtered[node] = all[node]
	all = filtered


static func get_root_path(node: Node) -> NodePath:
	if is_instance_valid(scene_root) and scene_root != node:
		return scene_root.get_path_to(node)
	return node.get_path()


func _ready() -> void:
	target = custom_target if is_instance_valid(custom_target) else get_parent()
	all[target] = self


func _exit_tree() -> void:
	_free_offload()
				
	all.erase(target)


func _free_offload() -> bool:
	if not offload_on_free:
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


func offload() -> void:
	_is_offloaded = true


func onload() -> void:
	_is_offloaded = false


func get_property_data() -> Dictionary[StringName, Variant]:
	if not is_instance_valid(target):
		printerr("%s cannot get property data from invalid target: %s" % target)
		return { }
	var property_data: Dictionary[StringName, Variant] = { }
	for property in saved_properties:
		if not property in target:
			continue
		property_data[property] = target.get(property)
	return property_data


func set_property_data(property_data: Dictionary[StringName, Variant]) -> void:
	if not is_instance_valid(target):
		printerr("%s cannot set property data to invalid target: %s" % target)
		return
	for property: StringName in property_data:
		target.set(property, property_data[property])


func save_properties() -> void:
	if save == null:
		printerr("%s cannot save properties with null save")
		return

	if save_mode == NodeSave.Mode.DYNAMIC and dynamic_uuid.is_empty():
		dynamic_uuid = get_uuid()

	var property_data: Dictionary[StringName, Variant] = { }
	
	# Determine if we should bypass property collection entirely
	var skip_properties := _is_offloaded and offload_mode == OffloadMode.IGNORE_PROPERTIES

	if not skip_properties:
		property_data = get_property_data()
		# Only block saving empty data if it's a standard static/global node and NOT offloaded
		if property_data.is_empty() and save_mode != NodeSave.Mode.DYNAMIC and not _is_offloaded:
			return 

	var node_save := NodeSave.new(saver_id, save_mode, get_scene_context(), property_data)
	node_save.offloaded = _is_offloaded

	match save_mode:
		NodeSave.Mode.DYNAMIC:
			node_save.make_dynamic(dynamic_uuid, target)
		NodeSave.Mode.STATIC_SCENE:
			node_save.make_static_scene(get_root_path(self))
		NodeSave.Mode.GLOBAL:
			node_save.make_global()

	var index := find_index()
	if index != -1:
		save.node_properties[index] = node_save
	else:
		save.node_properties.append(node_save)


func load_properties() -> void:
	if save == null:
		printerr("%s cannot load properties with null save")
		return

	var index := find_index()
	if index == -1:
		return

	var node_save: NodeSave = save.node_properties[index]
	
	_is_offloaded = node_save.offloaded
	if node_save.offloaded:
		match offload_mode:
			OffloadMode.FREE:
				if is_instance_valid(target):
					target.queue_free()
				return
			OffloadMode.IGNORE_PROPERTIES:
				return
			OffloadMode.DISABLED:
				pass # Load properties normally

	set_property_data(node_save.properties)


func get_uuid() -> StringName:
	return StringName("%s_%s" % [str(ResourceUID.create_id()), str(randi())])


func find_index() -> int:
	var current_scene := get_scene_context()

	for i in range(save.node_properties.size()):
		var node_save: NodeSave = save.node_properties[i]
		if node_save.mode != save_mode:
			continue

		match save_mode:
			NodeSave.Mode.DYNAMIC:
				if node_save.dynamic_uuid == dynamic_uuid and not dynamic_uuid.is_empty():
					return i
			NodeSave.Mode.STATIC_SCENE:
				if node_save.saver_id == saver_id and node_save.scene_context == current_scene and node_save.relative_path == get_root_path(self):
					return i
			NodeSave.Mode.GLOBAL:
				if node_save.saver_id == saver_id:
					return i
	return -1
