extends StateMachine
class_name EntityController3D

signal updated_entity(to: Entity3D)

@export var entity_type_state_map: Dictionary[String, String]
@export var initial_entity: Entity3D

var entity: Entity3D

func update_entity(to: Entity3D) -> void:
	entity = to
	for child in get_children():
		if child is State:
			child.root = entity
	
	if is_instance_valid(entity) and entity.type in entity_type_state_map:
		enter_state(entity_type_state_map[entity.type])
	
	updated_entity.emit(to)

static var _entity_controller_map: Dictionary[Entity3D, EntityController3D]

static func get_controller(of: Entity3D) -> EntityController3D:
	if of in _entity_controller_map:
		return _entity_controller_map[of]
	return null

func is_controlling() -> bool:
	return is_instance_valid(entity)

func _ready() -> void:
	if root == null:
		root = initial_entity
	super()
	update_entity(initial_entity)
	_entity_controller_map[entity] = self
