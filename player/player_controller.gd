extends EntityController3D

const MOUSE_SENSITIVITY := 0.35

const ACTION_MOVE_LEFT := "move_left"
const ACTION_MOVE_RIGHT := "move_right"
const ACTION_MOVE_FORWARD := "move_forward"
const ACTION_MOVE_BACKWARD := "move_backward"

const ACTION_JUMP := "jump"
const ACTION_TOGGLE_MOUSE_CAPTURE := "ui_cancel"
const ACTION_INTERACT := "interact"
const ACTION_USE_PRIMARY := "use_primary"

const ACTION_DROP := "drop"

@export var head: Node3D
@export var current_collision_shape: CollisionShape3D
@export var rotation_base: Node3D

var using_sick_controls := false

func _ready() -> void:
	MouseModeController.capture() # Capture mouse

func turn_head(relative: Vector2) -> void:
	if using_sick_controls:
		original_entity.rotate_vertical(relative.y * MOUSE_SENSITIVITY)
		original_entity.rotate_horizontal(relative.x * MOUSE_SENSITIVITY)
		return
		
	original_entity.rotate_vertical(-relative.y * MOUSE_SENSITIVITY)
	original_entity.rotate_horizontal(-relative.x * MOUSE_SENSITIVITY)

func get_motion_vector() -> Vector2:
	if using_sick_controls:
		return Input.get_vector(
			"move_right",
			"move_left",
			"move_forward",
			"move_backward"
		)
	
	return Input.get_vector(
			"move_left",
			"move_right",
			"move_backward",
			"move_forward"
		)

func update(_delta: float) -> void:
	if entity.type == "boat":
		boat_update()
		return
	
	# Move
	entity.move_planar(
		get_motion_vector().normalized()
	)
	
	if Input.is_action_just_pressed(ACTION_JUMP):
		entity.jump()
	
	if Input.is_action_just_pressed(ACTION_DROP):
		entity.drop_current_item()

func boat_update() -> void:
	pass

func _input(event: InputEvent) -> void:
	if not is_controlling():
		return
	
	# Turn head based on mouse movement
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		turn_head(event.relative * MOUSE_SENSITIVITY)
	#if event.is_action_pressed(ACTION_TOGGLE_MOUSE_CAPTURE):
		#MouseModeController.toggle(Input.MOUSE_MODE_CAPTURED, Input.MOUSE_MODE_VISIBLE)
	
	if not entity.type == "player":
		return
	
	if event.is_action_pressed(ACTION_INTERACT):
		entity.interact()
	
	if Input.is_action_pressed(ACTION_USE_PRIMARY):
		entity.use_item()

func get_accel_dir() -> Vector3:
	return Util.vec2to3(
		get_motion_vector(),
		Util.VECTOR3Y
	)
