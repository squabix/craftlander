class_name LinePlayer3D
extends Node3D

@export var lines: Dictionary[StringName, AudioStreamPlayer3D]

var _current: AudioStreamPlayer3D


func say(line: StringName) -> void:
	var player := lines.get(line) as AudioStreamPlayer3D
	if player == null:
		Util.node_error("%s has no line '%s'", self, line)
		return

	if is_instance_valid(_current):
		_current.stop()
	_current = player
	player.play()
