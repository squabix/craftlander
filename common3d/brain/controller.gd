extends Node
class_name Controller3D

@export var entity: Entity3D

static var _entity_brains: Dictionary

@onready var original_entity: Entity3D = entity

static func get_controller(of: Entity3D) -> Controller3D:
	if of in _entity_brains:
		return _entity_brains[of]
	return null

func is_controlling() -> bool:
	return is_instance_valid(entity)

func _ready() -> void:
	entity = original_entity

func _enter_tree() -> void:
	_entity_brains[entity] = self

func _process(delta: float) -> void:
	if entity == null:
		return
	update(delta)

func update(_delta: float) -> void:
	pass
