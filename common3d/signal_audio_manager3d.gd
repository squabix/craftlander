class_name SignalAudioManager3D
extends Node3D

@export var signal_players: Dictionary[StringName, AudioStreamPlayer3D]

func _ready() -> void:
	for signal_name in signal_players:
		if not get_parent().has_signal(signal_name):
			Util.node_error("%s cannot play audio for nonexistant signal '%s'", self, signal_name)
			continue
		
		var player := signal_players[signal_name]
		if not is_instance_valid(player):
			Util.node_error("%s cannot play audio for signal '%s' with invalid AudioStreamPlayer3D")
			continue
		
		get_parent().connect(signal_name, player.play)
