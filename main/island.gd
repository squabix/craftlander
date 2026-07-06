extends Node3D

const ISLAND_CENTER_SPAWN_HEIGHT := 55.0

enum PlayerSpawnMode {BOAT, ISLAND_CENTER}

@export var player: Player
@export var boat_driver_seat: Seat3D
@export var current_player_spawn_mode := PlayerSpawnMode.BOAT
@export var mesh_aggregator: MeshInstanceAggregator3D
@export var aggregate_props := true

func _ready() -> void:
	if aggregate_props:
		EventBus.subscribe("island_populated", mesh_aggregator.aggregate)
	match current_player_spawn_mode:
		PlayerSpawnMode.BOAT:
			boat_driver_seat.mount(player)
		PlayerSpawnMode.ISLAND_CENTER:
			player.global_position = Vector3(0.0, ISLAND_CENTER_SPAWN_HEIGHT, 0.0)
