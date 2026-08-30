class_name PlayerSprintingState
extends PlayerMoveState

const MIN_FORWARD_MOTION: float = 0.7
const STAMINA_COST := 0.25

func _ready() -> void:
	move_mode = preload("res://player/states/player_sprinting_move_mode.tres")

func is_walking_forward() -> bool:
	return root.last_motion_direction.z <= -MIN_FORWARD_MOTION

func physics_update(_delta: float) -> void:
	stamina.spend(STAMINA_COST)

func update(_delta: float) -> void:
	
	# Crouching is currently disabled
	#if Input.is_action_just_pressed("crouch") and root.is_on_floor():
		#transition_to(&"Crouching")
	
	# 'elif' when crouching enabled
	if not (stamina.is_usable() and is_walking_forward()):
		transition_to(&"Walking")
