class_name Save
extends Resource

const SCENE_EXTENSION := ".tscn"

@export var tags: Array[StringName]
@export var node_properties: Array[NodeSave] = []

@export_group("Dates")
@export var creation_datetime: Dictionary
@export var write_datetime: Dictionary

static var _scene_paths_by_file_name: Dictionary[String, Array] = { }
static var _scene_paths_indexed := false

var _node_save_index: Dictionary[String, int] = { }
var _node_save_index_built := false


func _ensure_node_save_index() -> void:
	if _node_save_index_built:
		return
	_node_save_index.clear()
	for i in range(node_properties.size()):
		var key := NodeSaver.get_lookup_key(node_properties[i])
		if not key.is_empty():
			_node_save_index[key] = i
	_node_save_index_built = true


func find_node_save_index(key: String) -> int:
	if key.is_empty():
		return -1
	_ensure_node_save_index()
	return _node_save_index.get(key, -1)


func register_node_save(key: String, index: int) -> void:
	if key.is_empty():
		return
	_ensure_node_save_index()
	_node_save_index[key] = index


static func load_from_disk(path: String) -> Save:
	if not ResourceLoader.exists(path):
		return null
	var res := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
	if not res is Save:
		return null
	return res


func write_to_disk(path: String) -> Error:
	write_datetime = Time.get_datetime_dict_from_system()
	if not ResourceLoader.exists(path):
		creation_datetime = write_datetime
	return ResourceSaver.save(self, path)


func is_tagged(tag: StringName) -> bool:
	return tag in tags


func add_tag(tag: StringName) -> bool:
	if tag in tags:
		return false
	tags.append(tag)
	return true


func get_node_saves(scene_root: Node, mode: NodeSave.Mode) -> Array[NodeSave]:
	if not is_instance_valid(scene_root):
		return []

	var node_saves: Array[NodeSave]
	node_saves.assign(
		node_properties.filter(
			func(node_save: NodeSave) -> bool: return (
						node_save.mode == mode
						and node_save.scene_context == scene_root.scene_file_path
				)
		)
	)
	return node_saves


func add_dynamic_nodes(scene_root: Node) -> void:
	if not is_instance_valid(scene_root):
		Util.node_error("%s cannot add dynamic nodes to invalid scene root %s", self, scene_root)
		return

	var tree := scene_root.get_tree()
	if not is_instance_valid(tree):
		Util.node_error("%s cannot add dynamic nodes to invalid tree: %s", self, tree)
		return

	# Gather all unspawned dynamic nodes belonging to this level
	var dynamic_entries := get_node_saves(scene_root, NodeSave.Mode.DYNAMIC)

	# Keeps track of newly spawned nodes by their tracking UUID
	var spawned_nodes: Dictionary[StringName, Node] = { }

	# Dependency resolution loop
	var progress := true
	while progress and not dynamic_entries.is_empty():
		progress = false
		var deferred_entries: Array[NodeSave] = []

		for node_save in dynamic_entries:
			var parent_node := get_parent_node(node_save, spawned_nodes, [scene_root, tree.root])
			if not is_instance_valid(parent_node):
				deferred_entries.append(node_save)
				continue

			if node_save.offloaded:
				progress = true
				continue

			var scene_path := resolve_scene_path(node_save)
			if scene_path.is_empty():
				Util.node_error("%s cannot add dynamic node from missing scene '%s'", self, node_save.scene_file_path)
				continue

			var instance: Node = load(scene_path).instantiate()
			if not is_instance_valid(instance):
				continue

			parent_node.add_child(instance)

			var uuid: StringName = node_save.dynamic_uuid
			spawned_nodes[uuid] = instance

			var saver: NodeSaver = Util.find_child_of_class(instance, &"NodeSaver")
			if is_instance_valid(saver):
				saver.dynamic_uuid = uuid
				saver.load_properties()

			progress = true # Mark progress so the loop continues processing defers

		dynamic_entries = deferred_entries


func resolve_scene_path(node_save: NodeSave) -> String:
	var uid_path := ResourceUID.uid_to_path(node_save.scene_uid) if ResourceUID.has_id(ResourceUID.text_to_id(node_save.scene_uid)) else ""
	var scene_path := uid_path if not uid_path.is_empty() else node_save.scene_file_path
	if scene_path.is_empty():
		return ""

	if not ResourceLoader.exists(scene_path):
		scene_path = _find_moved_scene_path(scene_path)
		if scene_path.is_empty():
			return ""

	node_save.scene_file_path = scene_path
	node_save.scene_uid = ResourceUID.path_to_uid(scene_path)
	return scene_path


func get_parent_node(node_save: NodeSave, spawned_nodes: Dictionary[StringName, Node], non_dynamic_parents: Array[Node]) -> Node:
	if node_save == null:
		Util.node_error("%s cannot get parent node from null node save: %s", self, node_save)
		return null

	if node_save.parent_type == NodeSave.ParentType.DYNAMIC:
		return spawned_nodes.get(node_save.parent_uuid, null)

	for parent in non_dynamic_parents:
		if not is_instance_valid(parent):
			continue
		return parent.get_node_or_null(node_save.parent_path)
	return null


static func _find_moved_scene_path(missing_path: String) -> String:
	if not _scene_paths_indexed:
		_index_scene_paths("res://")
		_scene_paths_indexed = true

	var candidates: Array = _scene_paths_by_file_name.get(missing_path.get_file(), [])
	var best_path := ""
	var best_similarity := 0.0
	var is_tied := false
	for candidate: String in candidates:
		var similarity := candidate.similarity(missing_path)
		if similarity > best_similarity:
			best_path = candidate
			best_similarity = similarity
			is_tied = false
		elif similarity == best_similarity:
			is_tied = true
	return "" if is_tied else best_path


static func _index_scene_paths(directory_path: String) -> void:
	var directory := DirAccess.open(directory_path)
	if directory == null:
		return

	for sub_directory in directory.get_directories():
		if not sub_directory.begins_with("."):
			_index_scene_paths(directory_path.path_join(sub_directory))

	for file_name in directory.get_files():
		var scene_name := file_name.trim_suffix(".remap")
		if not scene_name.ends_with(SCENE_EXTENSION):
			continue
		if not _scene_paths_by_file_name.has(scene_name):
			_scene_paths_by_file_name[scene_name] = []
		_scene_paths_by_file_name[scene_name].append(directory_path.path_join(scene_name))
