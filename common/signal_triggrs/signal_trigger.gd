class_name SignalTrigger
extends Node

@export var custom_target: Node
@export var signal_name: StringName


func _ready() -> void:
	var target := custom_target if is_instance_valid(custom_target) else get_parent()
	target.connect(signal_name, trigger)


func trigger(..._args: Array) -> void:
	pass
