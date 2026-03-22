extends State

func enter() -> void:
	var dismounted_player: Player = %DriverSeat.dismount()
	if dismounted_player != null:
		dismounted_player.respawn_point_node = %DriverSeat
