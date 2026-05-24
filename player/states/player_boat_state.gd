extends StateMachine

func enter() -> void:
	enter_state(str(root.state_machine.current))
