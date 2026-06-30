class_name SignalStateTrigger
extends SignalTrigger

@export var state_machine: StateMachine
@export var state_name: String
@export var from_state_whitelist: Array[String]


func _ready() -> void:
	if not is_instance_valid(state_machine):
		printerr(self, "has no state machine")
		return

	if state_name.is_empty():
		printerr(self, "has no state to transition to")
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
