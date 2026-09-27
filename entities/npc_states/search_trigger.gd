class_name SearchTrigger
extends SignalStateTrigger

@export var sight: RadialSight3D


func trigger(...args: Array) -> void:
	if disabled:
		return

	var attacker := get_attacker(args)
	if not is_instance_valid(attacker) or sight.does_see_target():
		return

	sight.target_position = attacker.global_position

	var searching := state_machine.get_state(state_name) as SearchingState
	if state_machine.is_currently(state_name) and searching != null:
		searching.restart()
		return

	super()


func get_attacker(args: Array) -> Node3D:
	if args.is_empty() or not args[0] is Damage:
		return null
	if not is_instance_valid(args[0].source):
		return null
	return args[0].source as Node3D
