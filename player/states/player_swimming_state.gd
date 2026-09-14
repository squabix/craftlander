class_name PlayerSwimmingState
extends PlayerMoveState

const ACTION_INTERACT := &"interact"
const STAMINA_COST := 0.12

func _ready() -> void:
	move_mode = preload("res://player/states/player_swmming_move_mode.tres")

func enter() -> void:
	super()
	root.set_character_stream_player(root.swim_player)

func update(_delta: float) -> void:
	if Input.is_action_just_pressed(ACTION_INTERACT):
		root.interact()

func physics_update(_delta: float) -> void:
	stamina.spend(STAMINA_COST)

	if not root.is_in_water:
		transition_to(&"Default")
		return

	root.move_planar(PlayerController.get_input_motion_vector().normalized())
