extends Node3D
class_name Seat3D

@export var vehicle: EntityVehicle3D
@export var is_driver: bool = true
@export var initial_entity: Entity3D

var mounted_entity: Entity3D
var mounted_controller: EntityController3D

func _ready() -> void:
	if initial_entity != null:
		mount(initial_entity)

func _process(delta: float) -> void:
	if is_instance_valid(mounted_entity):
		mounted_entity.global_position = global_position

func mount(entity: Entity3D) -> bool:
	
	# Cannot mount new entity when already mounted
	if is_instance_valid(mounted_entity):
		return false
	
	mounted_entity = entity
	mounted_controller = EntityController3D.get_controller(mounted_entity)
	if mounted_controller:
		mounted_controller.entity = vehicle
	
	return true

func dismount() -> void:
	if is_instance_valid(mounted_entity):
		mounted_controller.entity = mounted_entity
	mounted_entity = null
	mounted_controller = null
