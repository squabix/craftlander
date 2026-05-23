extends Node3D
class_name InventoryDropper3D

enum DeathDropMode {EVERYTHING, RANDOM, NEXT, NONE}

static var rigid_item_pickup_scene := load("res://defaults/default_rigid_item_pickup.tscn")
static var all_dropped_pickups: Array[Node]

@export var inventory: Inventory
@export var position_offset: Vector3
@export var rotation_offset: Vector3

@export_group("On Ready")
@export var drop_on_ready := false
@export var on_ready_index := -1

@export_group("On Death")
@export var health: Health
@export var death_drop_mode: DeathDropMode
@export var death_drop_quantity := 1

@onready var parent := get_tree().root

static func _transform_pickup(pickup: RigidItemPickup3D, dropper: InventoryDropper3D) -> void:
	var pickup_base_transform := dropper.global_transform
	var pickup_position_offset := dropper.position_offset
	var pickup_rotation_offset := dropper.rotation_offset
	
	await dropper.get_tree().process_frame
	
	if not is_instance_valid(pickup):
		return
	
	pickup.global_transform = pickup_base_transform
	pickup.global_position += pickup_position_offset
	pickup.global_rotation_degrees += pickup_rotation_offset

static func clear_dropped_pickups() -> void:
	for pickup in all_dropped_pickups:
		if is_instance_valid(pickup):
			pickup.queue_free()
	all_dropped_pickups = []

func _ready() -> void:
	if is_instance_valid(health): health.died.connect(die) # Drop items on death
	if drop_on_ready: drop(on_ready_index)

func add_pickup(item: Item) -> RigidItemPickup3D:
	var pickup := RigidItemPickup3D.from_item(item, rigid_item_pickup_scene)
	if pickup == null:
		printerr(self, " cannot add null pickup")
		return
	
	parent.add_child(pickup)
	InventoryDropper3D.all_dropped_pickups.append(pickup)
	InventoryDropper3D._transform_pickup(pickup, self)
	return pickup

func drop(index: int=-1) -> Node3D:
	var instance := get_instance(index)
	
	if instance == null:
		return
	
	# Failed to remove item (doesn't exist)
	if inventory.remove_instance(instance, 1) > 0:
		printerr(self, " cannot remove nonexistant item ", instance.item, " from ", inventory)
		return null
	
	return add_pickup(instance.item)

func get_instance(index) -> ItemInstance:
	return inventory.get_instance(inventory.get_random_index_weighted() if index == -1 else index)

func drop_everything() -> void:
	if inventory == null or inventory.item_instances.is_empty():
		return
	
	for i in inventory.size:
		drop(i)

func die() -> void:
	match death_drop_mode:
			
			# Drop nothing
			DeathDropMode.NONE:
				pass
			
			# Drop random item(s)
			DeathDropMode.RANDOM:
				for i in death_drop_quantity:
					drop()
			
			# Drop next available item(s)
			DeathDropMode.NEXT:
				for i in death_drop_quantity:
					drop(inventory.get_first_empty_index())
			
			# Drop everything
			DeathDropMode.EVERYTHING:
				drop_everything()
