extends EntityController3D

const TRANSITION_CHASE_TIME := 3.0

@onready var default_machine: StateMachine = $Default

func _ready() -> void:
	pass
	#default_machine.transition_to("BlindChase")
	#await get_tree().create_timer(TRANSITION_CHASE_TIME).timeout
	#default_machine.transition_to("NavChase")
