@abstract
class_name Util
extends Object

const VECTOR3X := Vector3i(1, 0, 0)
const VECTOR3Y := Vector3i(0, 1, 0)
const VECTOR3Z := Vector3i(0, 0, 1)

const BUILT_IN_INPUT_ACTIONS: Array[String] = [
	"ui_accept", "ui_select", "ui_cancel", "ui_focus_next", "ui_focus_prev", "ui_left", "ui_right", "ui_up", "ui_down", 
	"ui_page_up", "ui_page_down", "ui_home", "ui_end", "ui_cut", "ui_copy", "ui_paste", "ui_undo", "ui_redo", 
	"ui_text_completion_query", "ui_text_completion_accept", "ui_text_completion_replace", "ui_text_newline", 
	"ui_text_newline_blank", "ui_text_newline_above",  "ui_text_indent", "ui_text_dedent", "ui_text_backspace", 
	"ui_text_backspace_word", "ui_text_backspace_word.macos", "ui_text_backspace_all_to_left", "ui_text_backspace_all_to_left.macos", 
	"ui_text_delete", "ui_text_delete_word", "ui_text_delete_word.macos", "ui_text_delete_all_to_right", 
	"ui_text_delete_all_to_right.macos", "ui_text_caret_left", "ui_text_caret_word_left", "ui_text_caret_word_left.macos", 
	"ui_text_caret_right", "ui_text_caret_word_right", "ui_text_caret_word_right.macos", "ui_text_caret_up", 
	"ui_text_caret_down", "ui_text_caret_line_start", "ui_text_caret_line_start.macos", "ui_text_caret_line_end", 
	"ui_text_caret_line_end.macos", "ui_text_caret_page_up", "ui_text_caret_page_down", "ui_text_caret_document_start", 
	"ui_text_caret_document_start.macos", "ui_text_caret_document_end", "ui_text_caret_document_end.macos", "ui_text_caret_add_below", 
	"ui_text_caret_add_below.macos", "ui_text_caret_add_above", "ui_text_caret_add_above.macos", "ui_text_scroll_up", 
	"ui_text_scroll_up.macos", "ui_text_scroll_down", "ui_text_scroll_down.macos", "ui_text_select_all", 
	"ui_text_select_word_under_caret", "ui_text_select_word_under_caret.macos", "ui_text_add_selection_for_next_occurrence", 
	"ui_text_skip_selection_for_next_occurrence", "ui_text_clear_carets_and_selection", "ui_text_toggle_insert_mode", 
	"ui_menu", "ui_text_submit", "ui_graph_duplicate", "ui_graph_delete", "ui_filedialog_up_one_level", 
	"ui_filedialog_refresh", "ui_filedialog_show_hidden", "ui_swap_input_direction"
]

# TODO: Make own node
static func disable_all_colliders(parent: Node) -> Array[Node]:
	if not is_instance_valid(parent):
		return []
	
	var disabled_colliders: Array[Node] = []
	
	for child in parent.get_children():
		if not is_instance_valid(child):
			continue
		
		disabled_colliders += disable_all_colliders(child)
		
		if disable_collider(child):
			disabled_colliders.append(child)
	
	return disabled_colliders

static func get_object_class(object: Object) -> String:
	var script: Script = object.get_script()
	return script.get_global_name() if script != null else object.get_class()

static func classify_dict_key(dictionary: Dictionary, default_to_builtin := true) -> String:
	if not dictionary.is_typed_key():
		return ""
	var typed_script: Script = dictionary.get_typed_key_script()
	if typed_script != null:
		return typed_script.get_global_name()
	var typed_class := dictionary.get_typed_key_class_name()
	if not typed_class.is_empty():
		return typed_class
	if not default_to_builtin:
		return ""
	return type_string(dictionary.get_typed_key_builtin())

static func classify_dict_value(dictionary: Dictionary, default_to_builtin := true) -> String:
	if not dictionary.is_typed_value():
		return ""
	var typed_script: Script = dictionary.get_typed_value_script()
	if typed_script != null:
		return typed_script.get_global_name()
	var typed_class := dictionary.get_typed_key_class_name()
	if not typed_class.is_empty():
		return typed_class
	if not default_to_builtin:
		return ""
	return type_string(dictionary.get_typed_value_builtin())

static func find_child_of_class(parent: Node, class_string: String) -> Node:
	for child in parent.get_children():
		if get_object_class(child) == class_string:
			return child
		var grandchild := find_child_of_class(child, class_string)
		if grandchild != null:
			return grandchild
	return null

static func find_stored_child_of_class(dictionary: Dictionary, parent: Node) -> Node:
	var class_string := classify_dict_value(dictionary, false)
	if not parent in dictionary:
		dictionary[parent] = find_child_of_class(parent, class_string)
	return dictionary[parent]

static func find_children_of_class(parent: Node, class_string: String) -> Array[Node]:
	var children: Array[Node] = []
	for child in parent.get_children():
		if get_object_class(child) == class_string:
			children.append(child)
		else:
			var grandchildren := find_children_of_class(child, class_string)
			if not grandchildren.is_empty():
				children.append_array(grandchildren)
	return children

static func snap_to_floor(
		node: Node3D,
		margin: float = 0.05,
		max_distance: float = 1000.0,
		collision_mask: int = 0xFFFFFFFF
	) -> bool:
	
	var world := node.get_world_3d()
	if world == null:
		return false
	
	var origin := node.global_transform.origin
	var to := origin + Vector3.DOWN * max_distance
	
	var query := PhysicsRayQueryParameters3D.create(origin, to)
	query.collision_mask = collision_mask
	query.exclude = [node]
	
	var result := world.direct_space_state.intersect_ray(query)
	if result.is_empty():
		return false
	
	node.global_transform.origin = result.position + Vector3.UP * margin
	
	return true

static func disable_collider(collider: Node) -> bool:
	var polygon2d := collider is CollisionPolygon2D
	var polygon3d := collider is CollisionPolygon3D
	var shape2d := collider is CollisionShape2D
	var shape3d := collider is CollisionShape3D
	
	if not (polygon2d or polygon3d or shape2d or shape3d):
		return false
	collider.set_deferred("disabled", true)
	return true

static func enable_collider(collider: Node) -> void:
	var polygon2d := collider is CollisionPolygon2D
	var polygon3d := collider is CollisionPolygon3D
	var shape2d := collider is CollisionShape2D
	var shape3d := collider is CollisionShape3D
	
	if not (polygon2d or polygon3d or shape2d or shape3d):
		return
	collider.set_deferred("disabled", false)

static func are_instances_valid(instances: Array) -> bool:
	for instance in instances:
		if not is_instance_valid(instance):
			return false
	return true

static func distance_sort_2d(nodes: Array, position: Vector2) -> Array:
	if nodes.is_empty():
		return [null]
	var custom_sort := func(a, b) -> bool:
		if not (is_instance_valid(b) or b is Node2D):
			return true
		if not (is_instance_valid(a) or a is Node2D):
			return false
		var dist_a := (a as Node2D).global_position.distance_squared_to(position)
		var dist_b := (b as Node2D).global_position.distance_squared_to(position)
		return dist_a < dist_b
	
	var duplicate := nodes.duplicate()
	duplicate.sort_custom(custom_sort)
	return duplicate

static func get_position3d(of: Variant) -> Vector3:
	var position := Vector3.ZERO
	
	if of is Vector3:
		position = of
	
	elif of is Node3D:
		if is_instance_valid(of):
			position = of.global_position
	
	return position

static func reset_local_transform_3d(node: Node3D) -> void:
	node.position = Vector3.ZERO
	node.rotation = Vector3.ZERO
	node.scale = Vector3.ONE

static func distance_sort_3d(nodes: Array, position: Vector3) -> Array[Node3D]:
	if nodes.is_empty():
		return [null]
	
	var is_valid := func(a) -> bool:
		return is_instance_valid(a) and a is Node3D
	
	var custom_sort := func(a, b) -> bool:
		if not (is_instance_valid(b) or b is Node3D):
			return true
		elif not (is_instance_valid(a) or a is Node3D):
			return false
		var dist_a: float = a.global_position.distance_squared_to(position)
		var dist_b: float = b.global_position.distance_squared_to(position)
		return dist_a < dist_b
	
	var duplicate: Array[Node3D]
	duplicate.assign(nodes.duplicate())
	duplicate.filter(is_valid).sort_custom(custom_sort)
	return (duplicate.filter(func(n): return n != null)) as Array[Node3D]

# TODO: Make own node
static func search_up_for_node(child: Node, check: Callable, ignore_children: bool=false) -> Node:
	if not is_instance_valid(child):
		return null
	print_debug(child.name)
	if check.call(child) == true:
		return child
	var parent := child.get_parent()
	if is_instance_valid(parent) and not ignore_children:
		var parent_result := search_down_for_node(parent, check)
		if parent_result != null:
			return parent_result
	return search_up_for_node(parent, check, ignore_children)

# TODO: Make own node
static func search_down_for_node(parent: Node, check: Callable) -> Node:
	if not is_instance_valid(parent):
		return null
	print_debug("        " + parent.name)
	if check.call(parent) == true:
		return parent
	for child in parent.get_children():
		var child_result := search_down_for_node(child, check)
		if child_result != null:
			return child_result
	return null

static func find_all_resources(resource_type: String, start_path: String = "res://") -> Array:
	var results: Array = []
	
	var scan_dir: Callable = func(path: String, function: Callable) -> void:
		var dir := DirAccess.open(path)
		if dir == null:
			return
	
		dir.list_dir_begin()
		while true:
			var dir_name := dir.get_next()
			if dir_name == "":
				break
			if dir_name.begins_with("."):
				continue
	
			var full_path := path.path_join(dir_name)
			if dir.current_is_dir():
				function.call(full_path, function)
			else:
				var res := load(full_path)
				if res != null and Util.get_object_class(res) == resource_type:
					results.append(res)
	
		dir.list_dir_end()
	
	scan_dir.call(start_path, scan_dir)
	return results

static func safe_free(node: Variant) -> bool:
	if node == null:
		return false
	if not node is Node:
		return false
	if not node.has_method("queue_free"):
		return false
	node.queue_free()
	return true

# TODO: Make own node
static func turn_off_all_particles(parent: Node) -> void:
	if not is_instance_valid(parent):
		return
	
	for child in parent.get_children():
		if not is_instance_valid(child):
			continue
		
		turn_off_all_particles(child)
		
		var cpu2d := child is CPUParticles2D
		var cpu3d := child is CPUParticles3D
		var gpu2d := child is GPUParticles2D
		var gpu3d := child is GPUParticles3D
		
		if cpu2d or cpu3d or gpu2d or gpu3d:
			child.one_shot = true
			child.emitting = false

static func freeze(node: Node) -> void:
	node.set_process(false)
	node.set_physics_process(false)

static func unfreeze(node: Node) -> void:
	node.set_process(true)
	node.set_physics_process(true)

static func round_places(x: float, places: int=1) -> float:
	return float(round(x * pow(10, places))) / pow(10, places)

static func round_vec3(v: Vector3, places: int=1) -> Vector3:
	var r := func(x): return round_places(x, places)
	return CustomVector3.new().default(r).classify().vector_call(v)

static func vec3to2(v: Vector3, axis: Vector3i) -> Vector2:
	match axis:
		VECTOR3X:
			return Vector2(v.y, v.z)
		VECTOR3Y:
			return Vector2(v.x, v.z)
		VECTOR3Z:
			return Vector2(v.x, v.y)
	return Vector2.ZERO

static func vec2to3(v: Vector2, axis: Vector3i) -> Vector3:
	match axis:
		VECTOR3X:
			return Vector3(0.0, v.x, v.y)
		VECTOR3Y:
			return Vector3(v.x, 0.0, v.y)
		VECTOR3Z:
			return Vector3(v.x, v.y, 0.0)
	return Vector3.ZERO

static func flatten_vec3(v: Vector3, axis: Vector3i) -> Vector3:
	match axis:
		VECTOR3X:
			return Vector3(0.0, v.y, v.z)
		VECTOR3Y:
			return Vector3(v.x, 0.0, v.z)
		VECTOR3Z:
			return Vector3(v.x, v.y, 0.0)
	return Vector3.ZERO

static func is_3d_axis(v: Vector3i) -> bool:
	return v == VECTOR3X or v == VECTOR3Y or v == VECTOR3Z

static func roll_basis_toward(from: Basis, toward: Vector3, axis: Vector3i, amount: float) -> Basis:
	toward = -Util.flatten_vec3(toward, axis) # Ensure the direction is flattened
	
	var normalized_cross_product: Vector3 = toward.cross(axis).normalized()
	
	# Can't create basis without normalized axis
	if not normalized_cross_product.is_normalized():
		return from
	
	return Basis(normalized_cross_product, amount * toward.length()) * from

static func get_ray_query_parameters_3d(from: Vector3, to: Vector3, collide_areas := false, collide_bodies := true) -> PhysicsRayQueryParameters3D:
	var parameters := PhysicsRayQueryParameters3D.new()
	parameters.from = from
	parameters.to = to
	parameters.collide_with_areas = collide_areas
	parameters.collide_with_bodies = collide_bodies
	return parameters

static func get_rotation_between_points_3d(a: Vector3, b: Vector3) -> Vector3:
	return Transform3D().looking_at(a.direction_to(b)).basis.get_euler()

static func get_spherical_velocity_rotation(velocity: Vector3, radius: float, delta: float) -> float:
	if radius <= 0.0:
		return 0.0
	return velocity.length() / radius * delta

static func lerp_look_at_3d(node: Node3D, position: Vector3, weight: float) -> void:
	node.global_rotation = lerp_angle_3d(
		node.global_rotation,
		get_rotation_between_points_3d(node.global_position, position),
		weight
	)

static func get_property_names(of: Object) -> PackedStringArray:
	var property_names: PackedStringArray = []
	for property in of.get_property_list():
		var property_name: String = property["name"]
		if property_name.is_empty():
			continue
		var first_char := property_name[0]
		if first_char == "_":
			continue
		if first_char == first_char.to_upper():
			continue
		property_names.append(property_name)
	return property_names

static func ghost(original: Node, duplicate: Node, properties: PackedStringArray, update_signal: Signal, do_ghost_children: bool = true) -> void:
	if not (is_instance_valid(original) and is_instance_valid(duplicate)):
		return
	
	if do_ghost_children:
		for i in original.get_child_count():
			ghost(original.get_child(i), duplicate.get_child(i), properties, update_signal)
	
	while true:
		await update_signal
		if not (is_instance_valid(original) and is_instance_valid(duplicate)):
			return
		
		for property in properties:
			if not (property in original and property in duplicate):
				continue
			duplicate.set(property, original[property])

static func debug_node(node: Node) -> void:
	if not is_instance_valid(node):
		return
	
	var debug_strings: PackedStringArray = [node, "named " + node.name]
	var append: Callable = func(...strings: Array) -> void:
		debug_strings.append_array(strings)
	if node is Node3D:
		node = node as Node3D
		append.call(
			"at " + str(node.global_position),
			"rotated " + str(node.global_rotation_degrees),
			"scaled " + str(node.global_scale)
		)
		if node is CharacterBody3D:
			append.call(
				"moving " + node.velocity
			)
	print(" ".join(debug_strings))

static func lerp_angle_3d(from: Vector3, to: Vector3, weight: float) -> Vector3:
	return Vector3(
		lerp_angle(from.x, to.x, weight),
		lerp_angle(from.y, to.y, weight),
		lerp_angle(from.z, to.z, weight)
	)

static func rad_to_deg_vec2(vector: Vector2) -> Vector2:
	return Vector2(
		rad_to_deg(vector.x),
		rad_to_deg(vector.y)
	)

static func get_mouse_position_3d(camera: Camera3D, mouse_position_2d: Vector2 = camera.get_viewport().get_mouse_position(), collide_areas:=false, collide_bodies:=true, in_space: bool=true, default_plane: Plane=Plane(Vector3.UP, 0.0), z_depth: float=1000.0, use_front_plane: bool=true) -> Vector3:
	var from := camera.project_ray_origin(mouse_position_2d)
	var to := camera.project_position(mouse_position_2d, z_depth)
	
	# Try to intersect ray with an object in 3D space
	if in_space:
		var space_intersection := camera.get_world_3d().direct_space_state.intersect_ray(
			get_ray_query_parameters_3d(
				from,
				to,
				collide_areas,
				collide_bodies
			)
		)
		if not space_intersection.is_empty():
			return space_intersection.position
	
	# Try to intersect ray with the default plane
	if default_plane != null:
		var default_plane_intersection: Variant = default_plane.intersects_ray(from, to)
		if default_plane_intersection != null:
			return default_plane_intersection 
	
	# Try to intersect ray with a plane in front of the camera
	if use_front_plane:
		var camera_forward := -camera.global_transform.basis.z.normalized()
		var front_plane := Plane(
			camera_forward,
			(camera.global_transform.origin + camera_forward * z_depth).dot(camera_forward)
		)
		var front_plane_intersection: Variant = front_plane.intersects_ray(from, to)
		if front_plane_intersection != null:
			return front_plane_intersection 
	
	# Failed to intersect ray
	return Vector3.ZERO

static func get_camera_rect(camera: Camera2D) -> Rect2:
	var pos := camera.position # Camera's center
	var half_size := camera.get_viewport_rect().size * 0.5
	return Rect2(pos - half_size, pos + half_size)
