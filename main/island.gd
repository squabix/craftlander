extends Node3D

const ISLAND_CENTER_SPAWN_HEIGHT := 55.0

enum PlayerSpawnMode {BOAT, ISLAND_CENTER}

@export_group("Player")
@export var player: Player
@export var player_spawn_mode := PlayerSpawnMode.BOAT

@export_group("Generation Components")
@export var island_generator: HeightMapTerrainGenerator
@export var nav_region: IslandNavRegion
@export var prop_populator: PropPopulator
@export var mesh_aggregator: MeshInstanceAggregator3D
@export var occluder_instance: HeightMapOccluderInstance
@export var docking_manager: DockingManager

func _ready() -> void:
	MouseModeController.show()
	get_tree().paused = true
	
	NodeSaver.scene_root = self
	
	seed(Main.base_seed)
	island_generator.generate()
	
	await (reload_save if Main.loaded_save.is_current_level_generated() else initial_save_load).call()
	
	NodeSaver.load_all()
	
	mesh_aggregator.aggregate()
	occluder_instance.generate()
	nav_region.reset.call_deferred()
	
	position_player_at_spawn()
	
	get_tree().paused = false
	MouseModeController.capture()

func initial_save_load() -> void:
	await island_generator.generated
		
	docking_manager.initialize()
	prop_populator.populate()
	
	await prop_populator.populated
	Main.loaded_save.mark_current_level_as_generated()

func reload_save() -> void:
	prop_populator.clear()
	Main.loaded_save.add_dynamic_nodes(self)
	await island_generator.generated

func position_player_at_spawn() -> void:
	match player_spawn_mode:
		PlayerSpawnMode.BOAT:
			docking_manager.boat.driver_seat.mount(player)
		PlayerSpawnMode.ISLAND_CENTER:
			player.global_position = Vector3(0.0, ISLAND_CENTER_SPAWN_HEIGHT, 0.0)
