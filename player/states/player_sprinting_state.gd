extends State

const MIN_FORWARD_MOTION: float = 0.7
const STAMINA_COST := 0.18

@onready var movement_mode: MovementMode3D = preload("res://player/states/player_sprinting_movement_mode.tres")

func is_walking_forward() -> bool:
	return root.last_motion_direction.z <= -MIN_FORWARD_MOTION

func enter() -> void:
	root.movement_mode = movement_mode

func update(_delta: float) -> void:
	%Stamina.spend(STAMINA_COST)
	if Input.is_action_just_pressed("crouch") and root.is_on_floor():
		transition_to("Crouching")
	elif not (%Stamina.is_usable() and is_walking_forward()):
		transition_to("Walking")
