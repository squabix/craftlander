extends Node3D
class_name Seat3D

@export var vehicle: EntityVehicle3D
@export var is_driver: bool = true
@export var initial_entity: Entity3D

var mounted_entity: Entity3D

func _ready() -> void:
	if initial_entity != null:
		mount(initial_entity)

func _process(_delta: float) -> void:
	if is_instance_valid(mounted_entity):
		mounted_entity.global_position = global_position

func get_controller() -> EntityController3D:
	return EntityController3D.get_controller(mounted_entity)

func mount(entity: Entity3D) -> bool:
	
	# Cannot mount new entity when already mounted
	if is_instance_valid(mounted_entity):
		return false
	
	mounted_entity = entity
	var mounted_controller := get_controller()
	if mounted_controller != null:
		mounted_controller.update_entity(vehicle)
	
	return true

func dismount() -> void:
	var mounted_controller := get_controller()
	if mounted_controller != null:
		mounted_controller.update_entity(mounted_entity)
	mounted_entity = null
	mounted_controller = null
