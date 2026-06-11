extends State

const MIN_FORWARD_MOTION: float = 0.7
const STAMINA_COST := 0.18

@export var stamina: Stamina

@onready var movement_mode: MovementMode3D = preload("res://player/states/player_sprinting_movement_mode.tres")

func is_walking_forward() -> bool:
	return root.last_motion_direction.z <= -MIN_FORWARD_MOTION

func enter() -> void:
	root.movement_mode = movement_mode

func update(_delta: float) -> void:
	stamina.spend(STAMINA_COST)
	
	# Crouching is currently disabled
	#if Input.is_action_just_pressed("crouch") and root.is_on_floor():
		#transition_to("Crouching")
	
	# 'elif' when crouching enabled
	if not (stamina.is_usable() and is_walking_forward()):
		transition_to("Walking")
