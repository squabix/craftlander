class_name EntityController3D
extends StateMachine

signal updated_entity(to: Entity3D)

static var _entity_controller_map: Dictionary[Entity3D, EntityController3D]

@export var entity_type_state_map: Dictionary[String, String]
@export var initial_entity: Entity3D

var entity: Entity3D


static func get_controller(of: Entity3D) -> EntityController3D:
	if of in _entity_controller_map:
		return _entity_controller_map[of]
	return null


func _ready() -> void:
	if root == null:
		root = initial_entity
	super()
	update_entity(initial_entity)
	_entity_controller_map[entity] = self


func update_entity(to: Entity3D) -> void:
	entity = to
	update_root(to)

	if is_instance_valid(entity) and entity.type in entity_type_state_map:
		enter_state(entity_type_state_map[entity.type])

	updated_entity.emit(to)


func is_controlling() -> bool:
	return is_instance_valid(entity)
