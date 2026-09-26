class_name EndingCaptainState
extends EndingCombatState

const FLASH_COLOR := Color.WHITE
const FLASH_HOLD := 0.05
const FLASH_FADE := 0.5
const REVEAL_HEIGHT := 1.5
const STATUS := "Fighting the Ghost Captain"

@export var resolved_state := &"Resolved"
@export var cue: MusicCue

@export_group("Cannons", "cannon")
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var cannon_boss_wave_interval := 7.0
@export var cannon_phase_intervals: Array[float] = [9.0, 7.0, 6.0] # seconds per boat, indexed by captain phase

@export_group("Reveal", "reveal")
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var reveal_hold := 0.9
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var reveal_shake := 0.06


func enter() -> void:
	encounter.wave_spawner.wave_started.connect(on_wave_started)
	encounter.wave_spawner.entity_spawned.connect(on_entity_spawned)
	super()


func exit() -> void:
	encounter.wave_spawner.wave_started.disconnect(on_wave_started)
	encounter.wave_spawner.entity_spawned.disconnect(on_entity_spawned)
	super()


func run() -> void:
	if not has_captain_spawner():
		encounter.abort()
		return

	encounter.play_cue(cue)
	encounter.hud.flash(FLASH_COLOR, FLASH_HOLD, FLASH_FADE)
	await play_entrance()


func has_captain_spawner() -> bool:
	if is_instance_valid(encounter.chest) and is_instance_valid(encounter.chest.captain_spawner):
		return true

	Util.node_error("%s cannot begin the boss wave without a captain spawner on %s", self, encounter.chest)
	return false


func play_entrance() -> void:
	var cutscene := encounter.cutscene
	var spawn_point := encounter.chest.captain_spawner.global_position
	var pan_time := encounter.wave_spawner.get_wave(EndingEncounter.BOSS_WAVE_INDEX).pause_length_begin

	await cutscene.begin(encounter.cutscene_camera_lift)
	if not is_alive():
		return

	await cutscene.look_toward(spawn_point + Vector3.UP * REVEAL_HEIGHT, pan_time)
	if not is_alive():
		return

	cutscene.shake(reveal_shake, reveal_hold)
	if not await wait(reveal_hold):
		return

	cutscene.face_subject(spawn_point)
	await cutscene.blend_back(encounter.cutscene_blend_back_time)


func on_wave_started(index: int) -> void:
	if index != EndingEncounter.BOSS_WAVE_INDEX:
		return

	for boat in encounter.island.boats:
		if is_instance_valid(boat):
			encounter.wave_spawner.disable_spawner(boat.spawner)

	encounter.island.set_cannons(cannon_boss_wave_interval)
	encounter.wave_spawner.enable_spawner(encounter.chest.captain_spawner)
	SteamManager.update_status(STATUS)


func on_entity_spawned() -> void:
	if is_instance_valid(encounter.captain):
		return

	var instance: Node3D = encounter.wave_spawner.active_instances.back()
	encounter.captain = Util.find_child_of_class(instance, &"GhostCaptain", true) as GhostCaptain
	if encounter.captain == null:
		Util.node_error("%s cannot find the captain brain on %s", self, instance)
		return

	encounter.captain.phase_changed.connect(on_captain_phase_changed)
	encounter.captain.health.died.connect(go_to.bind(resolved_state), CONNECT_ONE_SHOT)


func on_captain_phase_changed(phase: int) -> void:
	if phase < cannon_phase_intervals.size():
		encounter.island.set_cannons(cannon_phase_intervals[phase])
