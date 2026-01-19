extends Node3D
class_name InventoryDropper3D

static var rigid_item_pickup_scene := load("res://defaults/default_rigid_item_pickup.tscn")

@export var inventory: Inventory
@export var position_offset: Vector3
@export var rotation_offset: Vector3
@export var health: Health
@export_group("On Ready")
@export var drop_on_ready := false
@export var on_ready_index := -1

@onready var parent := get_tree().root

func _ready() -> void:
	if health:
		health.died.connect(drop_everything)
	if drop_on_ready:
		drop(on_ready_index)

func drop(index: int=-1) -> Node3D:
	if index == -1:
		index = inventory.get_random_index_weighted()
	
	if not inventory.is_index_valid(index):
		return
	var instance := inventory.get_instance(index)
	var item := inventory.get_instance(index).item
	
	# Failed to remove item (doesn't exist)
	if inventory.remove_instance(instance, 1) > 0:
		printerr(self, " cannot remove nonexistant item ", item, " from ", inventory.item_instances)
		return null
	
	var pickup := RigidItemPickup3D.from_item(item, rigid_item_pickup_scene)
	if pickup == null:
		printerr(self, " cannot drop null pickup")
		return
	
	parent.add_child(pickup)
	
	await get_tree().process_frame
	
	pickup.global_transform = global_transform
	pickup.global_position += position_offset
	pickup.global_rotation_degrees += rotation_offset
	
	return pickup

func drop_everything() -> void:
	if inventory == null or inventory.item_instances.is_empty():
		return
	
	for i in inventory.size:
		drop(i)
