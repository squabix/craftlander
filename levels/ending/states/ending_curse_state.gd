class_name EndingCurseState
extends EndingState

const FLASH_COLOR := Color(1.0, 0.1, 0.06)
const FLASH_HOLD := 0.25
const FLASH_FADE := 0.9
const SWEEP_SETTLE := 1.0
const STATUS := "Facing the Ghost Fleet"

@export var waves_state := &"Waves"
@export var cue: MusicCue

@export_group("Sweep", "sweep")
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var sweep_time := 7.0
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var sweep_min_dwell := 3.0
@export_custom(PROPERTY_HINT_NONE, "suffix:m/s") var sweep_boat_speed := 50.0
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var sweep_dock_aim_height := 3.0


func run() -> void:
	encounter.begin_lockdown()
	SteamManager.update_status(STATUS)
	encounter.hud.flash(FLASH_COLOR, FLASH_HOLD, FLASH_FADE)

	await get_tree().process_frame
	if not is_alive() or not is_instance_valid(encounter.chest):
		return

	encounter.island.begin_curse()
	encounter.play_cue(cue)
	if not await play_fleet_cutscene():
		return

	enable_missing_spawners()
	go_to(waves_state)


func play_fleet_cutscene() -> bool:
	await encounter.cutscene.begin(encounter.cutscene_curse_camera_lift)
	if not is_alive():
		return false

	var plan := plan_sweep()
	var dwell := launch_boats(plan)
	encounter.cutscene.camera.global_rotation = Vector3(plan.pitch_at(0.0), plan.start_yaw, 0.0)
	if not await wait(dwell):
		return false

	await encounter.cutscene.sweep(plan, sweep_time)
	if not is_alive() or not await wait(SWEEP_SETTLE):
		return false

	await encounter.cutscene.blend_back(encounter.cutscene_blend_back_time)
	return is_alive()


func plan_sweep() -> Cutscene3D.SweepPlan:
	var aim_points: Array[Vector3] = []
	for manager in encounter.island.ghost_docking_managers:
		aim_points.append(manager.boat_dock_point.global_position + Vector3.UP * sweep_dock_aim_height)

	return encounter.cutscene.plan_sweep(encounter.cutscene.camera.global_position, aim_points)


func launch_boats(plan: Cutscene3D.SweepPlan) -> float:
	var managers := encounter.island.ghost_docking_managers
	var travel_times: Array[float] = []
	for manager in managers:
		var distance := manager.boat_adder.global_position.distance_to(manager.boat_dock_point.global_position)
		travel_times.append(distance / sweep_boat_speed)

	var first_index := plan.fractions.find(plan.fractions.min())
	var dwell := maxf(travel_times[first_index], sweep_min_dwell)
	for i in managers.size():
		var arrival_time := dwell + plan.fractions[i] * sweep_time
		launch_boat_after(managers[i], maxf(arrival_time - travel_times[i], 0.0))

	return dwell


func launch_boat_after(manager: DockingManager, delay: float) -> void:
	if delay > 0.0 and not await wait(delay):
		return

	var boat := encounter.wave_spawner.arrive(manager)
	if is_instance_valid(boat):
		encounter.island.add_boat(boat)


func enable_missing_spawners() -> void:
	for boat in encounter.island.boats:
		if is_instance_valid(boat) and not encounter.wave_spawner.is_enabled(boat.spawner):
			Util.node_error("%s is enabling the spawner of %s, which has not docked", self, boat)
			encounter.wave_spawner.enable_spawner(boat.spawner)
