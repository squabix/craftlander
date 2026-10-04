class_name SignalSpawnTrigger
extends SignalTrigger

@export var spawner: Spawner3D


func trigger(..._args: Array) -> void:
	if disabled or not is_instance_valid(spawner):
		return
	spawner.spawn()
