class_name SoundNode2D
extends Node2D

@export var sound: Sound
@export var autoplay: bool


func _ready() -> void:
	if autoplay:
		play()


func play() -> void:
	SoundManager.play2d(sound, global_position)
