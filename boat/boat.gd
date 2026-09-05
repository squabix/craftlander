class_name Boat
extends EntityVehicle3D

signal docked

const DOCK_HEIGHT := 0.4

@export var driver_seat: Seat3D
@export var state_machine: StateMachine

var dock_position: Vector3:
	set(to):
		dock_position = to
		dock_position.y = DOCK_HEIGHT


func _ready() -> void:
	set_physics_process(false)
	global_position.y = DOCK_HEIGHT


func get_current_state() -> State:
	if state_machine == null:
		return null
	return state_machine.get_state(state_machine.current)
