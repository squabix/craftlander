extends Node3D
class_name ItemVisualsContainer3D

const GHOSTED_ANIMATION_PROPERTIES: PackedStringArray = [
	"position",
	"rotation"
]

@export var item_holder: ItemHolder3D
@export var inventory_holder_link: InventoryHolderLink
@export var visuals_scale_ratio := 1.0
@export var disable_shadows := false

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

func update_visuals() -> void:
	reset_visuals()
	instance = item_holder.item_instance
	
	# Cannot update visuals if no instance/item
	if instance == null:
		return
	if instance.item == null:
		return
	# if not instance in inventory_holder_link.inventory.item_instances:
	# 	return
	# Free current visuals
	Util.safe_free(contained_visuals)
	
	# Wait for visuals to be set when item's scene is set up
	if not instance.item.is_scene_set_up:
		await instance.item.scene_set_up
		
		# Return if visuals are still not set
		if instance.item.visuals == null:
			return
	
	# Ghost a duplicate of visuals to copy animation
	contained_visuals = instance.item.visuals.duplicate()
	add_child(contained_visuals)
	contained_visuals.show()
	Util.ghost(
		instance.item.visuals,
		contained_visuals,
		GHOSTED_ANIMATION_PROPERTIES,
		get_tree().process_frame
	)
	if disable_shadows:
		for mesh_instance in Util.find_children_of_class(contained_visuals, "MeshInstance3D"):
			mesh_instance.cast_shadow = false
	contained_visuals.position = Vector3.ZERO
	contained_visuals.scale *= visuals_scale_ratio
