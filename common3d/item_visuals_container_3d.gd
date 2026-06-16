extends Node3D
class_name ItemVisualsContainer3D

const GHOSTED_ANIMATION_PROPERTIES: PackedStringArray = [
	"position",
	"rotation"
]

@export var item_holder: ItemHolder3D
@export var inventory_holder_link: InventoryHolderLink
@export var visuals_scale_ratio := 1.0
@export var do_disable_shadows := false
@export_flags_3d_render var layers := 1

var instance: ItemInstance
var contained_visuals: Node3D

func _ready() -> void:
	if is_instance_valid(inventory_holder_link):
		inventory_holder_link.changed.connect(update_visuals)
		if item_holder == null:
			item_holder = inventory_holder_link.item_holder
	
	await get_tree().process_frame
	update_visuals()

func reset_visuals() -> void:
	for child in get_children():
		Util.safe_free(child)

func ensure_item_visuals() -> bool:
	if instance.item.is_scene_set_up:
		return true
	await instance.item.scene_set_up
	return instance.item.visuals != null

func update_visuals() -> void:
	reset_visuals()
	instance = item_holder.item_instance
	
	# Cannot update visuals if no instance/item
	if instance == null or instance.item == null:
		return
	
	# Free current visuals
	Util.safe_free(contained_visuals)
	
	# Wait for visuals to be set when item's scene is set up
	if not await ensure_item_visuals():
		return
	
	# Ghost a duplicate of visuals to copy animation
	contained_visuals = instance.item.visuals.duplicate()
	add_child(contained_visuals)
	Util.ghost(
		instance.item.visuals,
		contained_visuals,
		GHOSTED_ANIMATION_PROPERTIES,
		get_tree().process_frame
	)
	
	contained_visuals.show()
	if do_disable_shadows: disable_shadows()
	
	# Transform contained visuals
	contained_visuals.position = Vector3.ZERO
	contained_visuals.scale *= visuals_scale_ratio
	
	# Set visual instances' layers
	var visual_instances := Util.find_children_of_class(contained_visuals, "VisualInstance3D")
	for visual_instance in visual_instances:
		visual_instance.layers = layers

func disable_shadows() -> void:
	for mesh_instance in Util.find_children_of_class(contained_visuals, "MeshInstance3D"):
		mesh_instance.cast_shadow = false
