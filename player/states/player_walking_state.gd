extends State

@onready var movement_mode: MovementMode3D = preload("res://player/states/player_walking_movement_mode.tres")

func enter() -> void:
	root.movement_mode = movement_mode

func update(_delta: float) -> void:
	if Input.is_action_just_pressed("crouch"):
		transition_to(%CrouchedState)
	elif Input.is_action_just_pressed("sprint"):
		transition_to(%SprintingState)
