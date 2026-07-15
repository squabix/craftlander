class_name VehicleMountArea3D
extends Interactable3D

@export var vehicle: EntityVehicle3D


func interact(_source: Node, _etc: Dictionary = { }) -> void:
	if not is_instance_valid(vehicle):
		return
	print("%s is mounting %s via %s" % [_source, vehicle, self])
	vehicle.fill_seats([_source as Entity3D])
