class_name PlayerController
extends EntityController3D

const ACTION_MOVE_LEFT := &"move_left"
const ACTION_MOVE_RIGHT := &"move_right"
const ACTION_MOVE_FORWARD := &"move_forward"
const ACTION_MOVE_BACKWARD := &"move_backward"

const ACTION_LOOK_LEFT := &"look_left"
const ACTION_LOOK_RIGHT := &"look_right"
const ACTION_LOOK_UP := &"look_up"
const ACTION_LOOK_DOWN := &"look_down"

const LOOK_SENSITIVITY := 0.35
const LOOK_SENSITIVITY_INPUT_MULTIPLIER := 350.0


static func get_input_motion_vector() -> Vector2:
	return Input.get_vector(
		ACTION_MOVE_LEFT,
		ACTION_MOVE_RIGHT,
		ACTION_MOVE_FORWARD,
		ACTION_MOVE_BACKWARD,
	)


static func get_input_look_vector() -> Vector2:
	return Input.get_vector(
		ACTION_LOOK_LEFT,
		ACTION_LOOK_RIGHT,
		ACTION_LOOK_UP,
		ACTION_LOOK_DOWN,
	)


func _ready() -> void:
	super()
	initial_entity.health.revived.connect(enter) # Default to initial state after revival


func _physics_process(delta: float) -> void:
	super(delta)
	
	var look_vector := get_input_look_vector()
	if not look_vector.is_zero_approx():
		turn_head(look_vector * LOOK_SENSITIVITY_INPUT_MULTIPLIER * delta)


func turn_head(relative: Vector2) -> void:
	# Invert y
	if GameSettings.config.get_value("gameplay", "invert_y", false) == true:
		relative.y *= -1.0

	var sensitivity: float = GameSettings.config.get_value("gameplay", "look_sensitivity", LOOK_SENSITIVITY)
	initial_entity.rotate_vertical(-relative.y * sensitivity)
	initial_entity.rotate_horizontal(-relative.x * sensitivity)


func handle_input(event: InputEvent) -> void:
	if not is_controlling():
		return
	super(event)

	# Turn head based on mouse movement
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		turn_head(event.relative * LOOK_SENSITIVITY)
