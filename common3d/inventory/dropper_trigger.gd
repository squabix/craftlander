class_name DropperTrigger
extends Node

@export var dropper: InventoryDropper3D
@export var health: Health
@export_range(0.0, 1.0) var chance := 1.0


func _ready() -> void:
	if not is_instance_valid(health):
		Util.node_error("%s cannot trigger drops without a health", self)
		return
	health.died.connect(trigger)


func trigger() -> void:
	if not is_instance_valid(dropper) or randf() > chance:
		return
	dropper.drop()
