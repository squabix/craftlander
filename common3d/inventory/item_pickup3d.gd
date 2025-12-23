extends Interactable3D
class_name ItemPickup3D

const FLOOR_MARGIN: float = 0.05

@export var item_instance: ItemInstance
@export var auto_generate_collision := true
@export var collision_scale: float = 0.1
@export var generate_floor_raycast := true

func _ready() -> void:
	var visuals: Node3D = item_instance.item.get_visuals_duplicate()
	add_child(visuals)
	visuals.global_transform = self.global_transform
	
	if generate_floor_raycast:
		Util.snap_to_floor(self, FLOOR_MARGIN)
	
	var mesh_instances := Util.find_children_of_class(visuals, "MeshInstance3D")
	# Generate collision from mesh instances
	if auto_generate_collision:
		print(mesh_instances)
		for mesh_instance in mesh_instances:
			if mesh_instance.mesh == null:
				continue
			
			var collision_shape := CollisionShape3D.new()
			collision_shape.shape = mesh_instance.mesh.create_convex_shape()
			add_child(collision_shape)
			collision_shape.scale = mesh_instance.scale * collision_scale
			collision_shape.global_position = mesh_instance.global_position
			print(scale)

func interact(_source: Node, _etc: Dictionary={}) -> void:
	var inventory: Inventory = Util.find_child_of_class(_source, "Inventory")
	inventory.add_item(item_instance.item, item_instance.quantity)
	queue_free()
