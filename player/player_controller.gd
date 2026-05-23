extends EntityController3D
class_name PlayerController

const ACTION_MOVE_LEFT := "move_left"
const ACTION_MOVE_RIGHT := "move_right"
const ACTION_MOVE_FORWARD := "move_forward"
const ACTION_MOVE_BACKWARD := "move_backward"

const MOUSE_SENSITIVITY := 0.35

@export var health: Health
@export var docking_hidden_interfaces: Array[Control] = []

func _ready() -> void:
	super()
	MouseModeController.capture() # Capture mouse
	health.revived.connect(enter) # Default to initial state after revival

func turn_head(relative: Vector2) -> void:
	
	# Invert y
	if GameSettings.config.get_value("gameplay", "invert_y", false) == true:
		relative.y *= -1.0
	
	root.rotate_vertical(-relative.y * MOUSE_SENSITIVITY)
	root.rotate_horizontal(-relative.x * MOUSE_SENSITIVITY)

static func get_input_motion_vector() -> Vector2:
	return Input.get_vector(
			ACTION_MOVE_LEFT,
			ACTION_MOVE_RIGHT,
			ACTION_MOVE_FORWARD,
			ACTION_MOVE_BACKWARD
		)

func handle_input(event: InputEvent) -> void:
	if not is_controlling():
		return
	super(event)
	
	# Turn head based on mouse movement
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		turn_head(event.relative * MOUSE_SENSITIVITY)
