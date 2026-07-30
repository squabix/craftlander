extends Node3D

@export var dropper: InventoryDropper3D

func _ready() -> void:
	if not is_instance_valid(dropper):
		printerr("%s cannot drop with invalid dropper: %s" % [self, dropper])
		return
	EventBus.subscribe(&"island_populated", dropper.drop.call_deferred)
