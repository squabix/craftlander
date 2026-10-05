class_name BeeNest
extends DestructibleResource

@export_group("Components")
@export var bee_spawners: Array[Spawner3D]


func _ready() -> void:
	super()
	if is_instance_valid(health):
		health.died.connect(EventBus.trigger.bind(&"bee_nest_destroyed"))
	for spawner in bee_spawners:
		if is_instance_valid(spawner):
			spawner.spawned.connect(_on_bee_spawned)


func _on_bee_spawned(bee: Node3D) -> void:
	var entity := bee as Entity3D
	if is_instance_valid(entity):
		EntityPopulator.report_death_on_exit(entity)
