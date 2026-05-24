extends EntityVehicle3D
class_name Boat

@export var max_turn_speed := 0.0
@export_range(0.0, 1.0) var turn_acceleration := 0.1 # Lower values mean heavier/drifting turns
@export var driver_seat: Seat3D
@export var state_machine: StateMachine

var dock_position: Vector3

var turn_velocity := 0.0 # The current rolling interpolation speed
var turn_amount := 0.0    # Stores the input direction for the physics frame

var forward_speed := 0.0 

func _process(delta: float) -> void:
	# Boat turns poorly when stationary, faster when moving
	forward_speed = velocity.dot(-transform.basis.z)
	var speed_factor := clampf(abs(forward_speed) / 5.0, 0.0, 1.0)
	
	# Interpolate the turn velocity toward our target input
	var target_turn_velocity = turn_amount * max_turn_speed * speed_factor
	turn_velocity = lerpf(turn_velocity, target_turn_velocity, turn_acceleration)
	
	rotation_degrees.y += turn_velocity * delta
	
	turn_amount = 0.0

func turn(amount: float) -> void:
	turn_amount = amount

func get_current_state() -> State:
	if state_machine == null:
		return null
	return state_machine.current
