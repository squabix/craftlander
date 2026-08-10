extends Unprojector3D

@export var health_bar: HealthBar
@export var type_label: Label
@export_group("External Dependencies")
@export var entity: Entity3D
@export var health: Health

func _ready() -> void:
	health_bar.health = health
	if is_instance_valid(entity) and is_instance_valid(type_label):
		type_label.text = entity.type
