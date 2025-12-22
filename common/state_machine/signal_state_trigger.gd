extends Node
class_name SignalStateTrigger

@export var custom_target: Node
@export var signal_name: StringName
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
	
	var target := custom_target if is_instance_valid(custom_target) else get_parent()
	target.connect(signal_name, trigger)

func trigger(..._args: Array) -> void:
	if from_state_whitelist.is_empty():
		state_machine.enter_state(state_name)
		return
	
	for state in from_state_whitelist:
		if state_machine.is_currently(state):
			state_machine.enter_state(state_name)
			return
