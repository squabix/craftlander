class_name SignalAudioManager3D
extends Node3D

@export var signal_players: Dictionary[StringName, AudioStreamPlayer3D]
@export var signal_3d_players: Dictionary[StringName, AudioStreamPlayer3D]

func _ready() -> void:
	for signal_name in signal_players:
		if not get_parent().has_signal(signal_name):
			Util.node_error("%s cannot play audio for nonexistant signal '%s'", self, signal_name)
			continue
		
		var player := signal_players[signal_name]
		if not is_instance_valid(player):
			Util.node_error("%s cannot play audio for signal '%s' with invalid AudioStreamPlayer3D")
			continue
		
		Util.connect_custom(player.play, Signal(get_parent(), signal_name))
	
	for signal_name in signal_3d_players:
		if not get_parent().has_signal(signal_name):
			Util.node_error("%s cannot play audio for nonexistant signal '%s'", self, signal_name)
			continue
		
		var player := signal_3d_players[signal_name]
		if not is_instance_valid(player):
			Util.node_error("%s cannot play audio for signal '%s' with invalid AudioStreamPlayer3D")
			continue
		
		get_parent().connect(signal_name, _play3d.bind(player))

func _play3d(...args: Array) -> void:
	if args.is_empty():
		return
	
	var player := args[-1] as AudioStreamPlayer3D
	if not is_instance_valid(player):
		return
	
	var position3d := Util.get_position3d(args[0])
	if position3d == Vector3.ZERO:
		return
	
	global_position = position3d
	player.play()
