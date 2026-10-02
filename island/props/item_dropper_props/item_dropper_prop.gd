extends Node3D

@export var dropper: InventoryDropper3D
@export_range(0.0, 1.0) var drop_chance := 1.0

func _ready() -> void:
	if drop_chance < 1.0 and randf() > drop_chance:
		return

	if not is_instance_valid(dropper):
		Util.node_error("%s cannot drop with invalid dropper: %s", self, dropper)
		return
	EventBus.subscribe(&"island_populated", dropper.drop.call_deferred)
