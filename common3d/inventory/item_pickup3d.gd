extends Interactable3D
class_name ItemPickup3D

@export var item_instance: ItemInstance

var collision_shape: CollisionShape3D

func _ready() -> void:
	var visuals: Node3D = item_instance.item.get_visuals_duplicate()
	add_child(visuals)
	for mesh in visuals.get_children():
		mesh = mesh as MeshInstance3D
		#collision_shape = mesh.create_convex_collision()

func interact(_source: Node, _etc: Dictionary={}) -> void:
	var inventory: Inventory = Util.find_child_of_class(_source, "Inventory")
	inventory.add_item(item_instance.item, item_instance.quantity)
	queue_free()
