extends Node3D

const ISLAND_CENTER_SPAWN_HEIGHT := 55.0

enum PlayerSpawnMode {BOAT, ISLAND_CENTER}

@export_group("Player")
@export var player: Player
@export var player_spawn_mode := PlayerSpawnMode.BOAT

@export_group("Terrain")
@export var island_generator: HeightMapTerrainGenerator
@export var nav_region: IslandNavRegion
@export var occluder_instance: HeightMapOccluderInstance

@export_group("Props")
@export var prop_populator: PropPopulator
@export var mesh_aggregator: MeshInstanceAggregator3D

@export_group("Boat")
@export var boat_adder: BoatAdder
@export var docking_manager: DockingManager

@export_group("Misc")
@export var pickup_container: Node3D


func _ready() -> void:
	MouseModeController.show()
	get_tree().paused = true
	
	var is_reloading: bool = Main.loaded_save.is_current_level_generated()
	
	Main.root.loading_screen.add_steps(
			"Generating terrain",
			"Restoring level state" if is_reloading else "Spawning props",
			"Loading save data",
			"Adding finishing touches",
		)
	
	NodeSaver.scene_root = self
	NodeSaver.offload_on_free_enabled = false
	InventoryDropper3D.default_pickup_parent = pickup_container
	
	seed(Main.base_seed)
	island_generator.generate()
	
	await (reload_save if is_reloading else initial_save_load).call()
	
	advance_step()
	NodeSaver.load_all()
	
	advance_step()
	mesh_aggregator.aggregate()
	occluder_instance.generate()
	nav_region.reset.call_deferred()
	
	MouseModeController.capture()
	
	await get_tree().physics_frame
	get_tree().paused = false
	advance_step()
	NodeSaver.offload_on_free_enabled = true
	print()


func advance_step() -> void:
	print(await Main.root.advance_loading_step())


func initial_save_load() -> void:
	advance_step()
	await island_generator.generated
	
	boat_adder.added_boat.connect(position_player_at_spawn)
	docking_manager.initialize()
	prop_populator.populate()
	
	advance_step()
	await prop_populator.populated
	
	Main.loaded_save.mark_current_level_as_generated()


func reload_save() -> void:
	docking_manager.boat_adder.added_boat.connect(position_player_at_spawn)
	prop_populator.clear()
	advance_step()
	
	await island_generator.generated
	
	advance_step()
	Main.loaded_save.add_dynamic_nodes(self)


func position_player_at_spawn() -> void:
	match player_spawn_mode:
		PlayerSpawnMode.BOAT:
			boat_adder.boat.driver_seat.mount(player)
		PlayerSpawnMode.ISLAND_CENTER:
			player.global_position = Vector3(0.0, ISLAND_CENTER_SPAWN_HEIGHT, 0.0)
