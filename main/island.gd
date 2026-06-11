extends Node3D

const ISLAND_CENTER_SPAWN_HEIGHT := 55.0

enum PlayerSpawnMode {BOAT, ISLAND_CENTER}

@export var player: Player
@export var boat_driver_seat: Seat3D
@export var current_player_spawn_mode := PlayerSpawnMode.BOAT

func _ready() -> void:
	match current_player_spawn_mode:
		PlayerSpawnMode.BOAT:
			boat_driver_seat.initial_entity = player
		PlayerSpawnMode.ISLAND_CENTER:
			boat_driver_seat.initial_entity = null
			player.global_position = Vector3(0.0, ISLAND_CENTER_SPAWN_HEIGHT, 0.0)
