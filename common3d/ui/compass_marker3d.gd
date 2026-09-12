class_name CompassMarker3D
extends Resource

@export var name := ""
@export var color := Color(0.0, 0.0, 0.0, 0.0)
@export var show_distance := true
@export var size_curve: Curve

var target: Node3D
var position_getter: Callable
var visibility_getter: Callable

func get_world_position() -> Vector3:
	if is_instance_valid(target):
		return target.global_position
	if position_getter.is_valid():
		return position_getter.call()
	return Vector3.ZERO


func is_trackable() -> bool:
	if is_instance_valid(target):
		return true
	return position_getter.is_valid()


func is_currently_visible() -> bool:
	if not is_trackable():
		return false
	if visibility_getter.is_valid():
		return visibility_getter.call()
	return true
