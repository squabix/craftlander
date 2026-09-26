class_name WaitForTargetState
extends SequenceState

@export var sight: RadialSight3D
@export var next_state: StringName
@export var target_group := &"player"
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var poll_interval := 0.2


func run() -> void:
	while is_alive() and not is_instance_valid(sight.target):
		lock_onto_target()
		if is_instance_valid(sight.target):
			break
		if not await wait(poll_interval):
			return

	go_to(next_state)


func lock_onto_target() -> void:
	var target := get_tree().get_first_node_in_group(target_group) as Node3D
	if target != null:
		sight.set_target(target)
