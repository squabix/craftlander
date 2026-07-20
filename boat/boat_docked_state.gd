extends State

@export var driver_seat: Seat3D
@export var interactable: Interactable3D

func enter() -> void:
	var dismounted_player: Player = driver_seat.dismount()
	if dismounted_player == null:
		return

	dismounted_player.respawn_point_node = driver_seat
	interactable.enable()
