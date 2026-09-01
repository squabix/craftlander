class_name CullingController3D
extends VisibleOnScreenNotifier3D

@export var root: Node3D

@export_group("Process")
@export var do_handle_process := true
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var on_screen_process_radius := INF
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var off_screen_process_radius := INF

@export_group("Visibility")
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var on_screen_visible_radius := INF
@export var visibility_control_list: Array[Node3D] = []
@export var control_visibility_deep := true
@export var use_visibility_range := true

@export_subgroup("Visibility Range Settings", "visibility_range")
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var visibility_range_fade_margin := 0.0
@export var visibility_range_dynamically_updates := false

var on_screen := false

static var active_count := 0
static var culled_count := 0

var _is_culled := false


func _ready() -> void:
	assert(is_instance_valid(root), "%s cannot cull invalid root (%s)" % [self, root])

	update_visibility_range()

	# Set on_screen via signals
	screen_entered.connect(set.bind(&"on_screen", true))
	screen_exited.connect(set.bind(&"on_screen", false))

	active_count += 1
	tree_exiting.connect(_on_tree_exiting, CONNECT_ONE_SHOT)


func evaluate_culling() -> void:
	assert(is_instance_valid(root), "%s cannot cull invalid root (%s)" % [self, root])

	var camera := get_viewport().get_camera_3d()
	if not is_instance_valid(camera):
		return

	if visibility_range_dynamically_updates:
		update_visibility_range()

	show()

	var distance_sq := global_position.distance_squared_to(camera.global_position)

	if on_screen:
		set_visibility(distance_sq < on_screen_visible_radius * on_screen_visible_radius)

	update_radius_process(distance_sq, on_screen_process_radius if on_screen else off_screen_process_radius)


func get_geometry_instances() -> Array[GeometryInstance3D]:
	var geometry_instances: Array[GeometryInstance3D] = []
	if visibility_control_list.is_empty():
		geometry_instances.assign(Util.find_children_of_class(root, &"GeometryInstance3D", true))
	elif control_visibility_deep:
		for node in visibility_control_list:
			geometry_instances.append_array(Util.find_children_of_class(node, &"GeometryInstance3D", true))
	else:
		geometry_instances.assign(visibility_control_list.filter(Util.is_object_class.bind(&"GeometryInstance3D")))
	return geometry_instances


func update_visibility_range() -> void:
	if not use_visibility_range:
		return
	for instance in get_geometry_instances():
		set_up_visibility_range(instance)


func set_visibility(to: bool) -> void:
	if not can_set_visibility():
		return

	if control_visibility_deep:
		_set_visibility_deep(to)
	else:
		_set_visibility_direct(to)


func disable_process() -> void:
	if not do_handle_process:
		return
	if not is_instance_valid(root):
		return
	if root.process_mode == Node.PROCESS_MODE_DISABLED:
		return
	root.process_mode = Node.PROCESS_MODE_DISABLED
	self.process_mode = Node.PROCESS_MODE_ALWAYS
	_is_culled = true
	culled_count += 1


func enable_process() -> void:
	if not do_handle_process:
		return
	if not is_instance_valid(root):
		return
	if root.process_mode == Node.PROCESS_MODE_INHERIT:
		return
	root.process_mode = Node.PROCESS_MODE_INHERIT
	self.process_mode = Node.PROCESS_MODE_INHERIT
	_is_culled = false
	culled_count -= 1


func set_up_visibility_range(instance: GeometryInstance3D) -> void:
	if not is_instance_valid(instance):
		return
	
	var use_fade_margin := use_visibility_range and visibility_range_fade_margin > 0.0
	
	instance.visibility_range_end = on_screen_visible_radius if use_visibility_range else 0.0
	if use_fade_margin:
		# Subtract fade margin from visibility range end so it does not exceed on scren visible radius (fade margin is added by default)
		instance.visibility_range_end -= visibility_range_fade_margin
	
	instance.visibility_range_end_margin = visibility_range_fade_margin if use_fade_margin else 0.0
	instance.visibility_range_fade_mode = (
			GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF if use_fade_margin
			else GeometryInstance3D.VISIBILITY_RANGE_FADE_DISABLED
	)


func update_radius_process(distance_sq: float, process_radius: float) -> void:
	if not do_handle_process:
		return
	
	if process_radius == INF:
		enable_process()
		return

	if process_radius == 0.0:
		disable_process()
		return

	if distance_sq < process_radius * process_radius:
		enable_process()
		return

	disable_process()


func can_set_visibility() -> bool:
	return not use_visibility_range and on_screen_visible_radius < INF and on_screen_visible_radius >= 0.0


func _set_visibility_direct(to: bool) -> void:
	if visibility_control_list.is_empty():
		root.visible = to
	else:
		for node in visibility_control_list:
			node.visible = to


func _set_visibility_deep(to: bool) -> void:
	if visibility_control_list.is_empty():
		Util.set_visibility_deep(root, to, [self])
	else:
		for node in visibility_control_list:
			Util.set_visibility_deep(node, to, [self])


func _on_tree_exiting() -> void:
	active_count -= 1
	if _is_culled:
		culled_count -= 1
