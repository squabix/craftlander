extends Node3D
class_name ItemVisualsContainer3D

const GHOSTED_ANIMATION_PROPERTIES: PackedStringArray = [
	"position",
	"rotation"
]

@export var inventory_holder_link: InventoryHolderLink

var instance: ItemInstance
var contained_visuals: Node3D

func _ready() -> void:
	inventory_holder_link.changed.connect(update_visuals)

func reset_visuals() -> void:
	for child in get_children():
		Util.safe_free(child)

func update_visuals() -> void:
	reset_visuals()
	instance = inventory_holder_link.get_current_instance()
	
	# Cannot update visuals if no instance/item
	if instance == null:
		return
	if instance.item == null:
		return
	
	# Free current visuals
	Util.safe_free(contained_visuals)
	
	# Wait for visuals to be set when item's scene is set up
	if instance.item.visuals == null:
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
	for mesh_instance in Util.find_children_of_class(contained_visuals, "MeshInstance3D"):
		mesh_instance.cast_shadow = false
	contained_visuals.position = Vector3.ZERO
