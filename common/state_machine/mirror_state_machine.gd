class_name MirrorStateMachine
extends StateMachine

@export var initial_target: StateMachine
@export var do_find_root_machine := true

var target: StateMachine


func _ready() -> void:
	super()
	if initial_target:
		set_target(initial_target)
	await get_tree().process_frame
	if target:
		enter_state(target.current)


func enter() -> void:
	if do_find_root_machine:
		set_target(Util.find_child_of_class(root, &"StateMachine"))
		enter_state(target.current)


func set_target(to: StateMachine) -> void:
	if target != null:
		target.entered_state.disconnect(enter_state)
	target = to
	if target != null:
		target.entered_state.connect(enter_state)
