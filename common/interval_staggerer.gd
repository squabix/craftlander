class_name IntervalStaggerer
extends Node

signal timeout

@export var disabled := false
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var base_interval := 1.0
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var stagger_amount := 0.003
@export var target_methods: Dictionary[Node, StringName]
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var initial_time_left := 0.0

var time_left := 0.0


func _ready() -> void:
	if initial_time_left > 0.0:
		time_left = stagger(initial_time_left)
		return
	reset()


func _process(delta: float) -> void:
	time_left -= delta
	if time_left <= 0.0:
		reset()
		call_target_methods()
		timeout.emit()


func reset() -> void:
	time_left = stagger(base_interval)


func stagger(value: float) -> float:
	return value + randf_range(-stagger_amount, stagger_amount)


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
