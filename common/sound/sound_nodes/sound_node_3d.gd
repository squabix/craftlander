extends Node3D
class_name SoundNode3D

@export var sound: Sound
@export var autoplay: bool

func _ready() -> void:
	if autoplay:
		play()


func play() -> void:
	SoundManager.play3d(sound, global_position)
