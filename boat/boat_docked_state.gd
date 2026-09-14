extends State

@export var driver_seat: Seat3D
@export var interactable: Interactable3D

func enter() -> void:
	root.docked.emit()
	if is_instance_valid(interactable):
		interactable.enable()

	driver_seat.dismount()
