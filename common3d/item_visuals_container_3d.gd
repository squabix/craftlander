@tool
class_name ItemVisualsContainer3D
extends Node3D

const GHOSTED_ANIMATION_PROPERTIES: PackedStringArray = [
	"position",
	"rotation",
]

@export var item_holder: ItemHolder3D
@export var item_override: Item
@export var do_ghost_animations := true
@export var visuals_scale_ratio := 1.0
@export var do_disable_shadows := false
@export var material_override: Material
@export_flags_3d_render var layers := 1

@export_tool_button("Display Item") var display_item_action := display_item

@export_group("Fit")
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var fit_size := 0.0

var fit_blend := 0.0:
	set(value):
		fit_blend = value
		apply_fit_blend()

var contained_visuals: Node3D

var has_fit_transforms := false
var natural_scale := Vector3.ONE
var natural_position := Vector3.ZERO
var fitted_scale := Vector3.ONE
var fitted_position := Vector3.ZERO


static func from_item(item: Item) -> ItemVisualsContainer3D:
	item.set_up_scene()
	var visuals_container := ItemVisualsContainer3D.new()
	visuals_container.item_override = item
	return visuals_container


func _ready() -> void:
	if Engine.is_editor_hint():
		return

	# Update visuals when inventory selector changes if using inventory holder
	if item_holder is InventoryHolder3D:
		item_holder.selector.selected_instance_changed.connect(update_visuals.call_deferred.unbind(1))

	update_visuals.call_deferred()


func reset_visuals() -> void:
	for child in get_children():
		# Scene-authored children belong to the user; only spawned visuals have no owner
		if Engine.is_editor_hint() and child.owner != null:
			continue
		Util.safe_free(child)


func display_item() -> void:
	reset_visuals()
	contained_visuals = null
	has_fit_transforms = false

	var item: Item = item_override
	if item == null and item_holder != null and item_holder.initial_item_instance != null:
		item = item_holder.initial_item_instance.item
	if item == null or item.scene == null:
		push_warning("%s has no item to display" % name)
		return

	var temp_instance := item.scene.instantiate()
	var target_node := temp_instance.get_node_or_null(item.visuals_scene_path)
	if target_node == null:
		push_warning("%s: item scene has no '%s' node" % [name, item.visuals_scene_path])
		temp_instance.free()
		return
	
	contained_visuals = target_node.duplicate()
	temp_instance.free()
	add_child(contained_visuals)
	contained_visuals.position = Vector3.ZERO
	contained_visuals.scale *= visuals_scale_ratio


func get_item() -> Item:
	if item_override != null:
		return item_override
	if item_holder == null:
		return null
	if item_holder.held_item_instance == null:
		return null
	return item_holder.held_item_instance.item


func update_visuals() -> void:
	reset_visuals()
	has_fit_transforms = false

	var item := get_item()

	# Cannot update visuals if no item
	if item == null:
		return

	# Free current visuals
	Util.safe_free(contained_visuals)

	# Wait for visuals to be set when item's scene is set up
	item.set_up_scene()

	contained_visuals = item.duplicate_visuals()

	add_child(contained_visuals)
	if item_override == null and do_ghost_animations:
		# Ghost a duplicate of visuals to copy animation
		Util.ghost(
			item.visuals,
			contained_visuals,
			GHOSTED_ANIMATION_PROPERTIES,
			get_tree().process_frame,
		)

	contained_visuals.show()
	if do_disable_shadows:
		disable_shadows()
	if material_override != null:
		apply_material_override()

	# Transform contained visuals
	contained_visuals.position = Vector3.ZERO
	contained_visuals.scale *= visuals_scale_ratio
	if fit_size > 0.0:
		cache_fit_transforms()
		apply_fit_blend()

	# Set visual instances' layers
	var visual_instances := Util.find_children_of_class(contained_visuals, &"VisualInstance3D")
	for visual_instance in visual_instances:
		visual_instance.layers = layers


func cache_fit_transforms() -> void:
	natural_scale = contained_visuals.scale
	natural_position = contained_visuals.position
	fitted_scale = natural_scale
	fitted_position = natural_position
	has_fit_transforms = true

	var bounds := get_visuals_aabb()
	var largest := maxf(bounds.size.x, maxf(bounds.size.y, bounds.size.z))
	if largest <= 0.0:
		return

	var factor := fit_size / largest
	fitted_scale = natural_scale * factor
	fitted_position = (natural_position - bounds.get_center()) * factor


func apply_fit_blend() -> void:
	if not has_fit_transforms or not is_instance_valid(contained_visuals):
		return

	contained_visuals.scale = natural_scale.lerp(fitted_scale, fit_blend)
	contained_visuals.position = natural_position.lerp(fitted_position, fit_blend)


func get_visuals_aabb() -> AABB:
	var merged := AABB()
	var has_bounds := false

	for node in Util.find_children_of_class(contained_visuals, &"MeshInstance3D", true):
		var mesh_instance := node as MeshInstance3D
		if mesh_instance.mesh == null or not mesh_instance.is_visible_in_tree():
			continue

		var bounds := get_relative_transform(mesh_instance) * mesh_instance.get_aabb()
		merged = merged.merge(bounds) if has_bounds else bounds
		has_bounds = true

	return merged


func get_relative_transform(node: Node3D) -> Transform3D:
	var result := Transform3D.IDENTITY
	var current: Node = node

	while current != self and current is Node3D:
		result = (current as Node3D).transform * result
		current = current.get_parent()

	return result


func disable_shadows() -> void:
	for mesh_instance in Util.find_children_of_class(contained_visuals, &"MeshInstance3D"):
		mesh_instance.cast_shadow = false


func apply_material_override() -> void:
	for mesh_instance: MeshInstance3D in Util.find_children_of_class(contained_visuals, &"MeshInstance3D"):
		if mesh_instance.mesh == null:
			continue
		for surface in mesh_instance.mesh.get_surface_count():
			mesh_instance.set_surface_override_material(surface, material_override)
