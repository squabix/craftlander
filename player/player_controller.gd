extends Controller3D

const HEAD_COLLISION_HEIGHT_MARGIN := 0.25
const HEAD_HEIGHT_LERP_SPEED := 0.3

const MOUSE_SENSITIVITY := 0.35


var crouch_speed := 0.2

@export var head: Node3D
@export var current_collision_shape: CollisionShape3D
@export var rotation_base: Node3D

func _ready() -> void:
	MouseModeController.capture() # Capture mouse

func turn_head(relative: Vector2) -> void:
	entity.rotate_vertical(-relative.y * MOUSE_SENSITIVITY)
	entity.rotate_horizontal(-relative.x * MOUSE_SENSITIVITY)

func update(_delta: float) -> void:
	adjust_head_to_collision()
	
	# Move
	entity.move_planar(
		Input.get_vector(
			"move_left",
			"move_right",
			"move_backward",
			"move_forward"
		).normalized()
	)
	
	if Input.is_action_just_pressed("jump"):
		entity.jump()

func adjust_head_to_collision() -> void:
	if not current_collision_shape:
		return
	head.position.y = lerp(
		head.position.y,
		current_collision_shape.shape.height - HEAD_COLLISION_HEIGHT_MARGIN,
		HEAD_HEIGHT_LERP_SPEED
	)

func _input(event: InputEvent) -> void:
	if not is_controlling():
		return
	
	# Turn head based on mouse movement
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		turn_head(event.relative * MOUSE_SENSITIVITY)
	
	if event.is_action_pressed("ui_cancel"):
		MouseModeController.toggle(Input.MOUSE_MODE_CAPTURED, Input.MOUSE_MODE_VISIBLE)

func get_accel_dir() -> Vector3:
	return Util.vec2to3(
		Input.get_vector(
			"move_left",
			"move_right",
			"move_forward",
			"move_backward"
		),
		Util.VECTOR3Y
	)
