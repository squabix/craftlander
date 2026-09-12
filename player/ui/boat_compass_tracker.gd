class_name BoatCompassTracker
extends Node

@export var compass: RadialCompass3D

var boat_adder: BoatAdder

var _marker: CompassMarker3D


func _ready() -> void:
	_marker = CompassMarker3D.new()
	_marker.position_getter = _get_boat_position
	_marker.visibility_getter = _is_boat_trackable
	_marker.color = Color.GOLD
	_marker.name = "Boat"
	compass.add_marker(_marker)


func _get_boat_position() -> Vector3:
	if is_instance_valid(boat_adder) and is_instance_valid(boat_adder.boat):
		return boat_adder.boat.global_position
	return Vector3.ZERO


func _is_boat_trackable() -> bool:
	if not is_instance_valid(boat_adder) or not is_instance_valid(boat_adder.boat):
		return false
	return boat_adder.boat.driver_seat.is_open()
