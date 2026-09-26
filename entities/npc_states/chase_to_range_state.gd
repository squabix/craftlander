class_name ChaseToRangeState
extends ChasingState

@export_group("Range")
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var timeout := 5.0
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var arrival_tolerance := 0.5

var target_range := 0.0
var return_state: StringName
var fail_state: StringName
var arrived_at: StringName

var _elapsed := 0.0


func enter() -> void:
	super()
	_elapsed = 0.0


func physics_update(delta: float) -> void:
	_elapsed += delta
	var distance := get_distance()
	if distance <= target_range or _elapsed >= timeout:
		finish(distance <= target_range + arrival_tolerance)
		return

	super(delta)


func begin(range_meters: float, to: StringName, on_fail := &"") -> void:
	target_range = range_meters
	return_state = to
	fail_state = to if on_fail == &"" else on_fail
	arrived_at = &""


func get_distance() -> float:
	return guide.get_distance_to_target()


func finish(arrived: bool) -> void:
	var next := return_state if arrived else fail_state
	if next == return_state:
		arrived_at = return_state
	transition_to(next)
