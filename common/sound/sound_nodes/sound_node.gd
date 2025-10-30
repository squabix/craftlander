extends Node
class_name SoundNode

signal started_play
signal ended_play

@export var sound: Sound
@export var autoplay: bool
@export var do_interupt: bool = true
@export var pitch_multiplier: float = 1.0
@export var volume_db_multiplier: float = 1.0

var is_playing: bool = false

func _ready() -> void:
	if autoplay:
		play()

func play() -> void:
	if is_playing and not do_interupt:
		return
	is_playing = true
	started_play.emit()
	await SoundManager.play(sound)
	ended_play.emit()
	is_playing = false
