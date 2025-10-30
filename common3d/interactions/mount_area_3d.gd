extends Interactable3D
class_name VehicleMountArea3D

@export var vehicle: EntityVehicle3D

func interact(root: Node, _etc: Dictionary={}) -> void:
	if not is_instance_valid(vehicle):
		return
	print(root, " is mounting ", vehicle, " via ", name)
	vehicle.fill_seats([root as Entity3D])
