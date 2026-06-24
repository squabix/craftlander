extends Interactable3D
class_name ItemPickup3D

signal picked_up

const FLOOR_MARGIN: float = 0.05

@export var item: Item
@export var auto_generate_collision := true
@export var collision_scale: float = 1.0
@export var generate_floor_raycast := true
@export var tooltip_prefix := "Pick up "
@export var tooltip_suffix := "?"

var visuals: Node3D

static func from_item(_item: Item) -> ItemPickup3D:
	var pickup := ItemPickup3D.new()
	pickup.item = _item
	return pickup

func update_visuals() -> void:
	visuals = item.duplicate_visuals()
	add_child(visuals)
	visuals.global_position = self.global_position
	visuals.global_rotation = self.global_rotation

func _ready() -> void:
	if item == null:
		printerr(self, " has no item instance")
		return
	update_visuals()
	
	enabled_tooltip = tooltip_prefix + item.name + tooltip_suffix
	
	if generate_floor_raycast:
		Util.snap_to_floor(self, FLOOR_MARGIN)
	
	if auto_generate_collision:
		generate_all_collision()

func generate_all_collision() -> Array[CollisionShape3D]:
	var collision_shapes: Array[CollisionShape3D] = []
	var mesh_instances := Util.find_children_of_class(visuals, "MeshInstance3D")
	
	for mesh_instance: MeshInstance3D in mesh_instances:
		if mesh_instance.mesh == null:
			continue
		collision_shapes.append(add_collision_shape(mesh_instance))
	
	return collision_shapes

func add_collision_shape(mesh_instance: MeshInstance3D) -> CollisionShape3D:
	var collision_shape := CollisionShape3D.new()
	collision_shape.shape = mesh_instance.mesh.create_convex_shape()
	add_child.call_deferred(collision_shape)
	collision_shape.global_transform = mesh_instance.global_transform
	#collision_shape.scale = mesh_instance.scale * visuals.scale * collision_scale
	return collision_shape

func interact(_source: Node, _etc: Dictionary={}) -> void:
	var inventory: Inventory = Util.find_child_of_class(_source, "Inventory")
	inventory.add_item(item, 1)
	Util.safe_free(self)
	picked_up.emit()
