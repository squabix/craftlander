extends EntityController3D
class_name PlayerController

const MOUSE_SENSITIVITY := 0.35

@onready var docking_hidden_interface: Array[Control] = [
	%BarContainer,
	%InventoryInterface,
	%Cursor
]

func _ready() -> void:
	super()
	
	MouseModeController.capture() # Capture mouse

func turn_head(relative: Vector2) -> void:
	root.rotate_vertical(-relative.y * MOUSE_SENSITIVITY)
	root.rotate_horizontal(-relative.x * MOUSE_SENSITIVITY)

func handle_input(event: InputEvent) -> void:
	if not is_controlling():
		return
	
	# Turn head based on mouse movement
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		turn_head(event.relative * MOUSE_SENSITIVITY)
