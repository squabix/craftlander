extends Node3D

@export var dropper: InventoryDropper3D

func _ready() -> void:
	EventBus.subscribe(&"island_populated", dropper.drop.call_deferred)
