class_name InventoryDropper3D
extends Spawner3D

signal dropped

enum DeathDropMode { EVERYTHING, RANDOM, NEXT, NONE }

static var rigid_item_pickup_scene := load("res://defaults/default_rigid_item_pickup.tscn")
static var all_dropped_pickups: Array[Node]

@export var inventory: Inventory

@export_group("Offset")
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var position_offset: Vector3
@export_custom(PROPERTY_HINT_NONE, "suffix:°") var rotation_offset: Vector3

@export_group("On Ready")
@export var drop_on_ready := false
@export var on_ready_index := -1

@export_group("On Death")
@export var health: Health
@export var death_drop_mode: DeathDropMode
@export var death_drop_quantity := 1


static func clear_dropped_pickups() -> void:
	for pickup in all_dropped_pickups:
		if is_instance_valid(pickup):
			pickup.queue_free()
	all_dropped_pickups = []


func _ready() -> void:
	super()
	if is_instance_valid(health):
		health.died.connect(die)
	if drop_on_ready:
		drop(on_ready_index)


func initialize_instance(instance: Node3D) -> void:
	super(instance)
	instance.global_position += position_offset
	instance.global_rotation_degrees += rotation_offset
	InventoryDropper3D.all_dropped_pickups.append(instance)


func add_pickup(item: Item) -> RigidItemPickup3D:
	var pickup := RigidItemPickup3D.from_item(item, rigid_item_pickup_scene)
	if pickup == null:
		Util.node_error("%s cannot add null pickup", self)
		return null
	spawn(pickup)
	return pickup


func drop(index: int = -1) -> Node3D:
	var instance := get_instance(index)

	if instance == null:
		return null

	if inventory.remove_instance(index, 1) > 0:
		Util.node_error("%s cannot remove nonexistant item %s from %s", self, instance.item, inventory)
		return null
	
	var pickup := add_pickup(instance.item)
	dropped.emit()
	return pickup


func get_instance(index: int) -> ItemInstance:
	return inventory.get_instance(inventory.get_random_index_weighted() if index == -1 else index)


func drop_everything() -> void:
	push_error("Drop everything is not currently implemented")


func die() -> void:
	match death_drop_mode:
		DeathDropMode.NONE:
			pass

		DeathDropMode.RANDOM:
			for i in death_drop_quantity:
				drop()

		DeathDropMode.NEXT:
			for i in death_drop_quantity:
				drop(inventory.find_empty_index())

		DeathDropMode.EVERYTHING:
			drop_everything()
