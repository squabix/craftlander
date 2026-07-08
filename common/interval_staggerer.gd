class_name IntervalStaggerer
extends Node

signal timeout

@export var disabled := false
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var base_interval := 1.0
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var stagger := 0.003
@export var target_methods: Dictionary[Node, StringName]

var time_left := 0.0

func _ready() -> void:
	reset()

func reset() -> void:
	time_left = base_interval + randf_range(-stagger, stagger)

func call_target_methods() -> void:
	if disabled:
		return
	
	for node in target_methods.keys():
		if not is_instance_valid(node):
			continue
		
		var method_name: StringName = target_methods[node]
		if not node.has_method(method_name):
			continue
		node.call(method_name)

func _process(delta: float) -> void:
	time_left -= delta
	if time_left <= 0.0:
		reset()
		call_target_methods()
		timeout.emit()
