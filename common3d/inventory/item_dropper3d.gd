class_name InventoryDropper3D
extends Spawner3D

signal dropped

enum DropMode { EVERYTHING, RANDOM, NEXT, NONE }

static var rigid_item_pickup_scene := load("res://common3d/inventory/default_rigid_item_pickup.tscn")
static var all_dropped_pickups: Array[Node]

@export var inventory: Inventory

@export_group("Drop")
@export var drop_mode := DropMode.RANDOM
@export var drop_quantity := 1

@export_group("Offset")
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var position_offset: Vector3
@export_custom(PROPERTY_HINT_NONE, "suffix:°") var rotation_offset: Vector3

@export_group("On Ready")
@export var drop_on_ready := false
@export var on_ready_index := -1


static func clear_dropped_pickups() -> void:
	for pickup in all_dropped_pickups:
		if is_instance_valid(pickup):
			pickup.queue_free()
	all_dropped_pickups = []


func _ready() -> void:
	super()
	if drop_on_ready:
		drop_index(on_ready_index, false)


func initialize_instance(instance: Node3D) -> void:
	super(instance)
	instance.global_position += position_offset
	instance.global_rotation_degrees += rotation_offset
	InventoryDropper3D.all_dropped_pickups.append(instance)
	instance.tree_exiting.connect(InventoryDropper3D.all_dropped_pickups.erase.bind(instance), CONNECT_ONE_SHOT)


func add_pickup(item: Item, recovers_from_underground := true) -> RigidItemPickup3D:
	var pickup := RigidItemPickup3D.from_item(item, rigid_item_pickup_scene)
	if pickup == null:
		Util.node_error("%s cannot add null pickup", self)
		return null
	if recovers_from_underground:
		pickup.enable_ground_recovery()
	spawn(pickup)
	return pickup


func drop(recovers_from_underground := true) -> void:
	match drop_mode:
		DropMode.NONE:
			pass

		DropMode.RANDOM:
			for i in drop_quantity:
				drop_index(-1, recovers_from_underground)

		DropMode.NEXT:
			for i in drop_quantity:
				drop_index(get_next_index(), recovers_from_underground)

		DropMode.EVERYTHING:
			drop_everything()


func drop_index(index: int, recovers_from_underground := true) -> Node3D:
	index = resolve_index(index)
	var instance := inventory.get_instance(index)

	if instance == null:
		return null

	if inventory.remove_instance(index, 1) > 0:
		Util.node_error("%s cannot remove nonexistant item %s from %s", self, instance.item, inventory)
		return null
	
	var pickup := add_pickup(instance.item, recovers_from_underground)
	dropped.emit()
	return pickup


func resolve_index(index: int) -> int:
	return inventory.get_random_index_weighted() if index == -1 else index


func get_next_index() -> int:
	var occupied := inventory.get_occupied_indicies()
	return occupied.front() if not occupied.is_empty() else -1


func drop_everything() -> void:
	push_error("Drop everything is not currently implemented")
