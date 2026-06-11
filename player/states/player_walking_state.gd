extends State

@export var stamina: Stamina

@onready var movement_mode: MovementMode3D = preload("res://player/states/player_walking_movement_mode.tres")

func enter() -> void:
	root.movement_mode = movement_mode

func update(_delta: float) -> void:
	if Input.is_action_just_pressed("sprint") and stamina.is_usable():
		transition_to("Sprinting")
	
	# Crouching is currently disabled
	#elif Input.is_action_just_pressed("crouch") and root.is_on_floor():
		#transition_to("Crouching")
