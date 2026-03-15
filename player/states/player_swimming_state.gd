extends State

@onready var movement_mode: MovementMode3D = preload("res://player/states/player_swmming_movement_mode.tres")

func enter() -> void:
	root.movement_mode = movement_mode

func update(_delta: float) -> void:
	if not root.is_in_water():
		transition_to("Default")
		return
	
	root.move_planar(PlayerController.get_input_motion_vector().normalized())
