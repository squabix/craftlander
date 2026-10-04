class_name EndingEncounter
extends Node

const BOSS_WAVE_INDEX := 3

@export var brain: StateMachine
@export var player: Player
@export var wave_spawner: GhostWaveSpawner
@export var cutscene: Cutscene3D
@export var island: EndingIsland
@export var music: MusicPlayer
@export var hud: EndingHUD

@export_group("Cutscene", "cutscene")
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var cutscene_camera_lift := 6.0
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var cutscene_curse_camera_lift := 12.0
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var cutscene_blend_back_time := 0.8

var chest: TreasureChest
var captain: GhostCaptain

var stage: StringName:
	get:
		return brain.current


func _ready() -> void:
	cutscene.began.connect(player.set_cutscene_locked.bind(true))
	cutscene.ended.connect(player.set_cutscene_locked.bind(false))


func _exit_tree() -> void:
	Main.saving_locked = false
	Main.autosave_locked = false


func begin_lockdown() -> void:
	Main.root.save_current_game()
	Main.saving_locked = true
	Main.autosave_locked = true
	island.lock_player_boat(true)


func end_lockdown() -> void:
	Main.saving_locked = false
	island.lock_player_boat(false)


func abort() -> void:
	end_lockdown()
	island.silence_cannons()


func play_cue(cue: MusicCue) -> void:
	music.play_cue(cue)
