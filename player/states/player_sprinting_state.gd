extends State

const MIN_FORWARD_MOTION: float = 0.7

@onready var movement_mode: MovementMode3D = preload("res://player/states/player_sprinting_movement_mode.tres")

func is_walking_forward() -> bool:
	return root.last_motion_direction.z <= -MIN_FORWARD_MOTION

func enter() -> void:
	root.movement_mode = movement_mode

func update(_delta: float) -> void:
	if Input.is_action_just_pressed("crouch") and root.is_on_floor():
		transition_to("Crouching")
	elif not is_walking_forward():
		transition_to("Walking")
