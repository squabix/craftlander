class_name MusicPlayer
extends Node

const SILENT_DB := -80.0
const PLAYER_COUNT := 2

@export var bus := &"Music"
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var default_fade_out := 1.5

var current_cue: MusicCue	

var _players: Array[AudioStreamPlayer] = []
var _active_index := 0
var _tweens: Dictionary[AudioStreamPlayer, Tween] = { }


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	EventBus.subscribe(&"player_died", _on_player_died, tree_exiting)

	for i in PLAYER_COUNT:
		add_player()


func add_player() -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.bus = bus
	player.volume_db = SILENT_DB
	player.finished.connect(_on_player_finished.bind(player))
	add_child(player)
	_players.append(player)
	return player


func play_cue(cue: MusicCue) -> void:
	if cue == current_cue:
		return

	var outgoing_fade := current_cue.fade_out if current_cue != null else default_fade_out
	_fade(_players[_active_index], SILENT_DB, outgoing_fade, true)
	
	current_cue = cue
	if cue == null or cue.stream == null:
		return

	_active_index = 1 - _active_index
	
	var incoming := _players[_active_index]
	incoming.stream = cue.stream
	incoming.volume_db = SILENT_DB
	incoming.play()
	_fade(incoming, cue.volume_db, cue.fade_in, false)


func set_paused(paused: bool) -> void:
	for player in _players:
		player.stream_paused = paused

	for tween in _tweens.values():
		if tween.is_valid():
			if paused:
				tween.pause()
			else:
				tween.play()


func _fade(player: AudioStreamPlayer, target_db: float, duration: float, stop_when_done: bool) -> void:
	var existing: Tween = _tweens.get(player)
	if existing != null and existing.is_valid():
		existing.kill()
	
	var tween := create_tween()
	tween.tween_property(player, ^"volume_db", target_db, maxf(duration, 0.01))
	if stop_when_done:
		tween.tween_callback(player.stop)
	
	_tweens[player] = tween


func _on_player_died(_is_in_water: bool) -> void:
	set_paused(true)


func _on_player_finished(player: AudioStreamPlayer) -> void:
	if current_cue != null and current_cue.loop and player == _players[_active_index]:
		player.play()
