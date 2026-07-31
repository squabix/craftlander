extends State

const ACTION_INTERACT := &"interact"
const STAMINA_COST := 0.12

@export var stamina: Stamina

@onready var move_mode: MoveMode = preload("res://player/states/player_swmming_move_mode.tres")

func enter() -> void:
	root.move_mode = move_mode

func handle_input(event: InputEvent) -> void:
	super(event)
	if event.is_action_pressed(ACTION_INTERACT):
		root.interact()

func physics_update(_delta: float) -> void:
	stamina.spend(STAMINA_COST)
	
	if not root.is_in_water:
		transition_to(&"Default")
		return
	
	root.move_planar(PlayerController.get_input_motion_vector().normalized())
