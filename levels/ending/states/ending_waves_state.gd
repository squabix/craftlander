class_name EndingWavesState
extends EndingCombatState

const STATUS := "Fighting the Ghost Fleet (wave %s)"

@export var captain_state := &"Captain"

@export_group("Cannons", "cannon")
@export var cannon_intervals: Array[float] = [12.0, 10.0, 8.0] # seconds per boat, indexed by wave
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var cannon_default_interval := 3.5


func enter() -> void:
	encounter.wave_spawner.wave_started.connect(on_wave_started)
	encounter.wave_spawner.wave_completed.connect(on_wave_completed)
	super()


func exit() -> void:
	encounter.wave_spawner.wave_started.disconnect(on_wave_started)
	encounter.wave_spawner.wave_completed.disconnect(on_wave_completed)
	super()


func run() -> void:
	encounter.wave_spawner.start(0)


func on_wave_started(index: int) -> void:
	var interval := cannon_intervals[index] if index < cannon_intervals.size() else cannon_default_interval
	encounter.island.set_cannons(interval)
	SteamManager.update_status(STATUS % (index + 1))


func on_wave_completed(index: int) -> void:
	encounter.island.silence_cannons()
	if index == EndingEncounter.BOSS_WAVE_INDEX - 1:
		go_to(captain_state)
