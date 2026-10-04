class_name Island
extends Node3D

const ISLAND_CENTER_SPAWN_HEIGHT := 55.0
const TIME_MULTIPLIER_TRAILER_MODE := 3.0

enum PlayerSpawnMode {BOAT, ISLAND_CENTER}

@export var resource: IslandResource

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

@export_group("Docking")
@export var player_boat_adder: BoatAdder
@export var docking_managers: Array[DockingManager]

@export_group("Name", "name")
@export_multiline() var name_format := "\n%s"
@export var name_label: Label
@export var name_anim_player: AnimationPlayer

@export_group("Sky Setting")
@export var world_environment: WorldEnvironment
@export var sun: DirectionalLight3D
@export var day_night_cycle: DayNightCycle

@export_group("Misc")
@export var spawn_container: Node3D
@export var music_player: MusicPlayer


func _ready() -> void:
	MouseModeController.show()
	get_tree().paused = true
	Spawner3D.spawning_enabled = false
	
	Util.nodestr_root = self
	
	var is_reloading: bool = Main.is_save_loaded and Main.loaded_save.is_current_level_generated()
	if is_reloading and not has_saved_props():
		Main.loaded_save.forget_level_generation(Main.loaded_save.current_level_index)
		is_reloading = false

	var master_bus_index := AudioServer.get_bus_index(&"Master")
	AudioServer.set_bus_mute(master_bus_index, true)
	if Main.root.loading_screen != null:
		Main.root.loading_screen.add_steps(
				"Generating terrain",
				"Restoring level state" if is_reloading else "Spawning props",
				"Loading save data",
				"Adding finishing touches",
			)
	
	NodeSaver.scene_root = self
	NodeSaver.offload_on_free_enabled = false
	Spawner3D.root = spawn_container
	
	seed(Main.base_seed)
	island_generator.generate()
	
	await (reload_save if is_reloading else initial_save_load).call()
	
	advance_step()
	NodeSaver.load_all()
	if is_reloading:
		place_unsaved_docks()
		add_missing_player_boat()

	update_sky_setting(not is_reloading)
	
	advance_step()
	mesh_aggregator.aggregate()
	occluder_instance.generate()
	nav_region.reset.call_deferred()
	
	MouseModeController.capture()
	
	await get_tree().physics_frame
	get_tree().paused = false
	advance_step()
	NodeSaver.offload_on_free_enabled = true
	show_name()
	await get_tree().process_frame
	AudioServer.set_bus_mute(master_bus_index, false)

	if music_player != null:
		music_player.play_cue(resource.music)


func has_saved_props() -> bool:
	var populator_path := get_path_to(prop_populator)
	for node_save in Main.loaded_save.get_node_saves(self, NodeSave.Mode.DYNAMIC):
		if node_save.parent_type == NodeSave.ParentType.RELATIVE and node_save.parent_path == populator_path:
			return true
	return false


func show_name() -> void:
	if Main.trailer_mode:
		return
	name_label.text = name_format % resource.name
	name_anim_player.play(&"show")


func advance_step() -> void:
	await Main.root.advance_loading_step()


func initial_save_load() -> void:
	advance_step()
	await island_generator.wait_until_generated()
	
	connect_player_boat_adder()
	for manager in docking_managers:
		manager.initialize()
	
	prop_populator.clear()
	await get_tree().process_frame
	Spawner3D.spawning_enabled = true
	prop_populator.populate()
	
	advance_step()
	await prop_populator.populated
	
	Main.loaded_save.mark_current_level_as_generated()
	save_props()


func save_props() -> void:
	NodeSaver.filter_all()
	for prop in prop_populator.get_children():
		var saver: NodeSaver = NodeSaver.all.get(prop)
		if is_instance_valid(saver) and saver.save_mode == NodeSave.Mode.DYNAMIC:
			saver.save_properties()


func connect_player_boat_adder() -> void:
	player_boat_adder.spawned.connect(position_player_at_spawn.unbind(1))
	player.boat_compass_tracker.boat_adder = player_boat_adder


func update_sky_setting(is_first_visit: bool) -> void:
	if is_first_visit:
		day_night_cycle.reset_to_day_start()
	day_night_cycle.palette = resource.sky_palette
	day_night_cycle.day_started.connect(SteamManager.achievements.on_day_survived)
	if Main.trailer_mode:
		day_night_cycle.cycle_speed_multiplier = TIME_MULTIPLIER_TRAILER_MODE


func reload_save() -> void:
	connect_player_boat_adder()
	prop_populator.clear()
	await get_tree().process_frame
	Spawner3D.spawning_enabled = true
	advance_step()
	
	await island_generator.wait_until_generated()
	
	advance_step()
	Main.loaded_save.add_dynamic_nodes(self)
	


func position_player_at_spawn() -> void:
	match player_spawn_mode:
		PlayerSpawnMode.BOAT:
			player_boat_adder.boat.driver_seat.mount(player)
		PlayerSpawnMode.ISLAND_CENTER:
			player.global_position = Vector3(0.0, ISLAND_CENTER_SPAWN_HEIGHT, 0.0)


func add_missing_player_boat() -> void:
	if is_instance_valid(player_boat_adder.boat):
		return

	for manager in docking_managers:
		if manager.boat_adder == player_boat_adder:
			manager.add_boat()
			return


func place_unsaved_docks() -> void:
	for manager in docking_managers:
		var saver: NodeSaver = NodeSaver.all.get(manager.dock)
		if is_instance_valid(saver) and saver.loaded:
			continue
		manager.place_dock()
