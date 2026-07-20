class_name NodeSave
extends Resource

enum Mode {
	STATIC_SCENE,
	GLOBAL,
	DYNAMIC,
	NONE,
}
enum ParentType {
	RELATIVE,
	DYNAMIC,
}

@export var saver_id: StringName
@export var mode := Mode.NONE
@export var scene_context: String
@export var properties: Dictionary[StringName, Variant] = { }

@export var dynamic_uuid: StringName
@export var scene_file_path: String

@export var parent_type: ParentType
@export var parent_uuid: StringName
@export var parent_path: NodePath
@export var relative_path: NodePath

@export var offloaded := false


func _init(save_saver_id: StringName = &"", save_mode: Mode = Mode.NONE, save_scene_context: String = "", property_data: Dictionary[StringName, Variant] = {}) -> void:
	saver_id = save_saver_id
	mode = save_mode
	scene_context = save_scene_context
	properties = property_data


func make_dynamic(uuid: StringName, target: Node) -> void:
	if not is_instance_valid(target):
		printerr("Cannot make %s dynamic with invalid target: %s" % [self, target])
		return
	
	mode = Mode.DYNAMIC
	dynamic_uuid = uuid
	scene_file_path = target.scene_file_path

	var parent := target.get_parent()
	var parent_saver: NodeSaver = NodeSaver.all.get(parent, null)

	if is_instance_valid(parent_saver) and parent_saver.save_mode == NodeSave.Mode.DYNAMIC:
		parent_type = NodeSave.ParentType.DYNAMIC
		parent_uuid = parent_saver.dynamic_uuid
	else:
		parent_type = NodeSave.ParentType.RELATIVE
		parent_path = NodeSaver.get_root_path(parent)


func make_static_scene(root_relative_path: NodePath) -> void:
	mode = Mode.STATIC_SCENE
	relative_path = root_relative_path


func make_global() -> void:
	mode = Mode.GLOBAL
