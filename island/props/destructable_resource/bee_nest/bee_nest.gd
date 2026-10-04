class_name BeeNest
extends DestructableResource


func _ready() -> void:
	super()
	if is_instance_valid(health):
		health.died.connect(EventBus.trigger.bind(&"bee_nest_destroyed"))
