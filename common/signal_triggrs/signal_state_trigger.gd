class_name SignalStateTrigger
extends SignalTrigger

@export var state_machine: StateMachine
@export var state_name: StringName
@export var from_state_whitelist: Array[StringName]


func _ready() -> void:
	if not is_instance_valid(state_machine):
		Util.node_error("%s has no state machine", self)
		return

	if state_name.is_empty():
		Util.node_error("%s has no state to transition to", self)
		return

	super()


func trigger(..._args: Array) -> void:
	if from_state_whitelist.is_empty():
		state_machine.enter_state(state_name)
		return

	for state in from_state_whitelist:
		if state_machine.is_currently(state):
			state_machine.enter_state(state_name)
			return
