extends Interactable3D
class_name VehicleMountArea3D

@export var vehicle: EntityVehicle3D

func interact(_source: Node, _etc: Dictionary={}) -> void:
	if not is_instance_valid(vehicle):
		return
	print(_source, " is mounting ", vehicle, " via ", name)
	vehicle.fill_seats([_source as Entity3D])
