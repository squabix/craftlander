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

static func _transform_pickup(pickup: RigidItemPickup3D, dropper: InventoryDropper3D) -> void:
	var pickup_base_transform := dropper.global_transform
	var pickup_position_offset := dropper.position_offset
	var pickup_rotation_offset := dropper.rotation_offset
	
	await dropper.get_tree().process_frame
	
	pickup.global_transform = pickup_base_transform
	pickup.global_position += pickup_position_offset
	pickup.global_rotation_degrees += pickup_rotation_offset

func _ready() -> void:
	if health:
		health.died.connect(drop_everything)
	if drop_on_ready:
		drop(on_ready_index)

func drop(index: int=-1) -> Node3D:
	if index == -1:
		index = inventory.get_random_index_weighted()
	
	if not inventory.is_index_valid(index):
		printerr(self, " cannot drop invalid index ", index, " from ", inventory)
		return
	
	var instance := inventory.get_instance(index)
	var item := inventory.get_instance(index).item
	
	# Failed to remove item (doesn't exist)
	if inventory.remove_instance(instance, 1) > 0:
		printerr(self, " cannot remove nonexistant item ", item, " from ", inventory)
		return null
	
	var pickup := RigidItemPickup3D.from_item(item, rigid_item_pickup_scene)
	if pickup == null:
		printerr(self, " cannot drop null pickup")
		return
	
	parent.add_child(pickup)
	
	InventoryDropper3D._transform_pickup(pickup, self)
	
	return pickup

func drop_everything() -> void:
	if inventory == null or inventory.item_instances.is_empty():
		return
	
	for i in inventory.size:
		drop(i)
