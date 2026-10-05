class_name VisibilityAnimationPlayer
extends AnimationPlayer

@export var show_on_play := true
@export var hide_on_finish := true
@export var deep := true

var _affected_nodes: Array[Node] = []


func _ready() -> void:
	animation_started.connect(_on_animation_started)
	animation_finished.connect(_on_animation_finished)


func disable_visibility_updates() -> void:
	show_on_play = false
	hide_on_finish = false


func is_affectable(node: Node) -> bool:
	return is_instance_valid(node) and node.has_method("show") and node.has_method("hide")


func get_track_node(path: NodePath) -> Node:
	return get_node(root_node).get_node(str(path).split(":")[0])


func _on_animation_started(anim_name: StringName) -> void:
	if not show_on_play:
		return

	_affected_nodes.clear()
	var anim: Animation = get_animation(anim_name)

	for i in anim.get_track_count():
		var target_node: Node = get_track_node(anim.track_get_path(i))
		if not is_affectable(target_node) or _affected_nodes.has(target_node):
			continue

		_affected_nodes.append(target_node)
		if deep:
			show_deep(target_node, true)
		else:
			target_node.show()


func _on_animation_finished(_anim_name: StringName) -> void:
	if not hide_on_finish:
		return

	var finished_nodes := _affected_nodes.duplicate()
	_affected_nodes.clear()

	for node in finished_nodes:
		MeshInstanceAggregator3D.set_multimesh_visibility_deep(node, true)

	for i in MeshInstanceAggregator3D.OVERLAP_FRAMES:
		await get_tree().process_frame

	if is_playing():
		for node in finished_nodes:
			MeshInstanceAggregator3D.set_multimesh_visibility_deep(node, false)
		return

	if not hide_on_finish:
		return

	for node in finished_nodes:
		if not is_instance_valid(node):
			continue
		if deep:
			Util.set_visibility_deep(node, false)
		else:
			node.hide()


func show_deep(node: Node, is_target := false) -> void:
	if not is_instance_valid(node):
		return

	if (node is CanvasItem or node is Node3D) and (is_target or not intentionally_hidden(node)):
		node.visible = true

	for child in node.get_children():
		show_deep(child, false)


func intentionally_hidden(node: Node) -> bool:
	return node is MeshInstance3D and not MeshInstanceAggregator3D.aggregated_mesh_instances.has(node)
