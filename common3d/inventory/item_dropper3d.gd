extends Node3D
class_name InventoryDropper3D

static var rigid_item_pickup_scene := load("res://defaults/default_rigid_item_pickup.tscn")

@export var inventory: Inventory
@export var position_offset: Vector3
@export var rotation_offset: Vector3

@onready var parent := get_tree().root

func drop() -> void:
	if inventory == null or inventory.item_instances.is_empty():
		return
	
	for instance in inventory.item_instances:
		if instance == null:
			continue
		
		var pickup := RigidItemPickup3D.from_item_instance(instance, rigid_item_pickup_scene)
		parent.add_child(pickup)
		pickup.global_transform = global_transform
		pickup.global_position += position_offset
		pickup.global_rotation_degrees += rotation_offset
		inventory.remove_instance(instance, instance.quantity)
