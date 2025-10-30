extends Node3D
class_name Seat3D

@export var vehicle: EntityVehicle3D
@export var is_driver: bool = true
@export var whitelisted_groups: Array[String]

class SeatedInstance:
	var entity: Entity3D
	var brain: Brain3D
	var previous_parent: Node
	var disabled_colliders: Array[Node]
	
	func _init(seat: Seat3D, seated_entity: Entity3D) -> void:
		entity = seated_entity
		if entity == null:
			return
		
		previous_parent = entity.get_parent()
		entity.reparent(seat)
		Util.reset_local_transform_3d(entity)
		entity.set_physics_process(false)
		disabled_colliders = Util.disable_all_colliders(entity)
		
		brain = Brain3D.get_brain(entity)
		brain.entity = seat.vehicle
	
	func revert() -> void:
		brain.entity = entity
		entity.reparent(previous_parent)
		entity.set_physics_process(true)
		for collider in disabled_colliders:
			collider.set_deferred("disabled", false)

var current_instance: SeatedInstance

func is_open() -> bool:
	return current_instance == null

func dismount(entity: Entity3D) -> void:
	if current_instance == null:
		return
	
	if entity != current_instance.entity:
		return
	
	if not is_instance_valid(entity):
		current_instance = null
		return
	
	# TODO: Copy position AND rotation of dismount area
	var dismount_position: Vector3 = get_dismount_position()
	if dismount_position != global_position:
		current_instance.entity.global_position = dismount_position
	
	current_instance.revert()
	current_instance = null

func get_dismount_position() -> Vector3:
	for dismount_area in vehicle.dismount_areas:
		#if not dismount_area.has_overlapping_bodies():
		return dismount_area.global_position
	return global_position

func is_whitelisted(entity: Entity3D) -> bool:
	return true
	if whitelisted_groups.is_empty():
		return true
	for group in whitelisted_groups:
		if entity.is_in_group(group):
			return true
	return false

func can_mount(entity: Entity3D) -> bool:
	return is_whitelisted(entity)

func get_dismount_signals(of: Entity3D) -> Array[Signal]:
	return [of.tree_exiting, of.dismount_requested]

func mount(entity: Entity3D) -> bool:
	if current_instance != null:
		return false
	
	if not is_whitelisted(entity):
		return false
	
	current_instance = SeatedInstance.new(self, entity)
	
	var bound_dismount: Callable = dismount.bind(entity)
	entity.tree_exiting.connect(bound_dismount)
	entity.dismount_requested.connect(bound_dismount)
	
	print(entity, " mounted ", vehicle.name, " on ", name)
	
	return true
