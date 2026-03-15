extends StateMachine

const ACTION_JUMP := "jump"
const ACTION_INTERACT := "interact"
const ACTION_USE_PRIMARY := "use_primary"
const ACTION_DROP := "drop"

func enter() -> void:
	super()
	%ItemVisualsContainer3D.show()
	for control in get_parent().docking_hidden_interface:
		control.show()

func handle_input(event: InputEvent) -> void:
	super(event)
	if event.is_action_pressed(ACTION_INTERACT):
		root.interact()
	if Input.is_action_pressed(ACTION_USE_PRIMARY):
		root.use_item()

func update(_delta: float) -> void:
	super(_delta)
	root.move_planar(PlayerController.get_input_motion_vector().normalized())
	
	if Input.is_action_just_pressed(ACTION_JUMP):
		root.jump()
	
	if Input.is_action_just_pressed(ACTION_DROP):
		root.drop_current_item()
