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

var contained_visuals: Node3D


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

	# Set visual instances' layers
	var visual_instances := Util.find_children_of_class(contained_visuals, &"VisualInstance3D")
	for visual_instance in visual_instances:
		visual_instance.layers = layers


func disable_shadows() -> void:
	for mesh_instance in Util.find_children_of_class(contained_visuals, &"MeshInstance3D"):
		mesh_instance.cast_shadow = false


func apply_material_override() -> void:
	for mesh_instance: MeshInstance3D in Util.find_children_of_class(contained_visuals, &"MeshInstance3D"):
		if mesh_instance.mesh == null:
			continue
		for surface in mesh_instance.mesh.get_surface_count():
			mesh_instance.set_surface_override_material(surface, material_override)
