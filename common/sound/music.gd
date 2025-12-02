extends Node
class_name Music

@export var sound: Sound
@export var auto_start := false

func _ready() -> void:
	if auto_start:
		SoundManager.loop(sound)
