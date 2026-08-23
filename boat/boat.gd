class_name Boat
extends EntityVehicle3D

@export var driver_seat: Seat3D
@export var state_machine: StateMachine

var dock_position: Vector3


func _ready() -> void:
	set_physics_process(false)


func get_current_state() -> State:
	if state_machine == null:
		return null
	return state_machine.get_state(state_machine.current)
