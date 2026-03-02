extends State

const ACTION_MOVE_LEFT := "move_left"
const ACTION_MOVE_RIGHT := "move_right"
const ACTION_MOVE_FORWARD := "move_forward"
const ACTION_MOVE_BACKWARD := "move_backward"

const ACTION_JUMP := "jump"
const ACTION_INTERACT := "interact"
const ACTION_USE_PRIMARY := "use_primary"
const ACTION_DROP := "drop"

func enter() -> void:
	%ItemVisualsContainer3D.show()
	for control in get_parent().docking_hidden_interface:
		control.show()

func handle_input(event: InputEvent) -> void:
	if event.is_action_pressed(ACTION_INTERACT):
		root.interact()
	if Input.is_action_pressed(ACTION_USE_PRIMARY):
		root.use_item()

static func get_motion_vector() -> Vector2:
	return Input.get_vector(
			ACTION_MOVE_LEFT,
			ACTION_MOVE_RIGHT,
			ACTION_MOVE_BACKWARD,
			ACTION_MOVE_FORWARD
		)

func update(_delta: float) -> void:
	root.move_planar(
		get_motion_vector().normalized()
	)
	print("Updated, moved")
	
	if Input.is_action_just_pressed(ACTION_JUMP):
		root.jump()
	
	if Input.is_action_just_pressed(ACTION_DROP):
		root.drop_current_item()
