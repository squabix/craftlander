extends Controller3D

const MOUSE_SENSITIVITY := 0.35

const ACTION_MOVE_LEFT := "move_left"
const ACTION_MOVE_RIGHT := "move_right"
const ACTION_MOVE_FORWARD := "move_forward"
const ACTION_MOVE_BACKWARD := "move_backward"

const ACTION_JUMP := "jump"
const ACTION_TOGGLE_MOUSE_CAPTURE := "ui_cancel"
const ACTION_INTERACT := "interact"
const ACTION_USE_PRIMARY := "use_primary"

const ACTION_SCROLL_UP := "scroll_up"
const ACTION_SCROLL_DOWN := "scroll_down"

const ACTION_DROP := "drop"

@export var head: Node3D
@export var current_collision_shape: CollisionShape3D
@export var rotation_base: Node3D

func _ready() -> void:
	MouseModeController.capture() # Capture mouse

func turn_head(relative: Vector2) -> void:
	entity.rotate_vertical(-relative.y * MOUSE_SENSITIVITY)
	entity.rotate_horizontal(-relative.x * MOUSE_SENSITIVITY)

func get_motion_vector() -> Vector2:
	return Input.get_vector(
			"move_left",
			"move_right",
			"move_backward",
			"move_forward"
		) 

func update(_delta: float) -> void:
	
	# Move
	entity.move_planar(
		get_motion_vector().normalized()
	)
	
	if Input.is_action_just_pressed(ACTION_JUMP):
		entity.jump()
	
	if Input.is_action_just_pressed(ACTION_DROP):
		entity.drop_current_item()

func _input(event: InputEvent) -> void:
	if not is_controlling():
		return
	
	# Turn head based on mouse movement
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		turn_head(event.relative * MOUSE_SENSITIVITY)
	
	if event.is_action_pressed(ACTION_TOGGLE_MOUSE_CAPTURE):
		MouseModeController.toggle(Input.MOUSE_MODE_CAPTURED, Input.MOUSE_MODE_VISIBLE)
	
	if event.is_action_pressed(ACTION_INTERACT):
		entity.interact()
	
	if event.is_action_pressed(ACTION_SCROLL_UP):
		entity.inventory_holder_link.scroll(-1)
	
	elif event.is_action_pressed(ACTION_SCROLL_DOWN):
		entity.inventory_holder_link.scroll(1)
	
	if Input.is_action_pressed(ACTION_USE_PRIMARY):
		entity.use_item()

func get_accel_dir() -> Vector3:
	return Util.vec2to3(
		get_motion_vector(),
		Util.VECTOR3Y
	)
