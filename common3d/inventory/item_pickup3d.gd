class_name ItemPickup3D
extends Interactable3D

signal picked_up

const FLOOR_MARGIN: float = 0.05

@export var item: Item
@export var auto_generate_collision := true
@export var collision_scale: float = 1.0
@export var generate_floor_raycast := true

@export_group("Tooltip")
@export var tooltip_format := "Pick up %s?"
@export var invalid_tooltip := "Pick up?"

@export_group("Visibility Fading")
@export var visibility_fading_enabled := false
@export var visibility_fading_distance := 50.0
@export var visibility_fading_margin := 5.0

var visuals: Node3D


static func from_item(_item: Item) -> ItemPickup3D:
	var pickup := ItemPickup3D.new()
	pickup.item = _item
	return pickup


func _ready() -> void:
	update_visuals()
	
	if visibility_fading_enabled:
		var geometry_instances: Array[GeometryInstance3D]
		geometry_instances.assign(Util.find_children_of_class(visuals, &"GeometryInstance3D").filter(is_instance_valid))
		for instance in geometry_instances:
			instance.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
			instance.visibility_range_end = visibility_fading_distance
			instance.visibility_range_end_margin = visibility_fading_margin

	tooltip_enabled = tooltip_format % item.name if is_instance_valid(item) else invalid_tooltip

	if generate_floor_raycast:
		Util.snap_to_floor(self, FLOOR_MARGIN)

	if auto_generate_collision:
		generate_all_collision(self)


func update_visuals() -> void:
	if item == null:
		printerr("%s cannot update visuals with null item" % self)
		return
	visuals = item.duplicate_visuals()
	add_child(visuals)
	visuals.global_position = self.global_position
	visuals.global_rotation = self.global_rotation


func generate_all_collision(target_parent: Node3D = self) -> Array[CollisionShape3D]:
	var collision_shapes: Array[CollisionShape3D] = []
	var mesh_instances := Util.find_children_of_class(visuals, &"MeshInstance3D")

	for mesh_instance: MeshInstance3D in mesh_instances:
		collision_shapes.append(add_collision_shape(mesh_instance, target_parent))

	return collision_shapes


func add_collision_shape(mesh_instance: MeshInstance3D, parent: Node) -> CollisionShape3D:
	if mesh_instance == null:
		return null
	if parent == null:
		return null
	if mesh_instance.mesh == null:
		return null

	var collision_shape := CollisionShape3D.new()
	collision_shape.shape = mesh_instance.mesh.create_convex_shape()

	parent.add_child(collision_shape)
	collision_shape.global_transform = mesh_instance.global_transform
	return collision_shape


func interact(_source: Node, _etc: Dictionary = { }) -> void:
	var inventory: Inventory = Util.find_child_of_class(_source, &"Inventory")
	inventory.add_item(item, 1)
	Util.safe_free(self)
	picked_up.emit()
