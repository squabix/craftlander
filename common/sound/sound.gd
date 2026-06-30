class_name Sound
extends Resource

@export var stream: AudioStream
@export var pitch_scale := 1.0
@export var volume_db := 1.0


func get_player() -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = pitch_scale
	return player


func get_player_2d(position: Vector2) -> AudioStreamPlayer2D:
	var player := AudioStreamPlayer2D.new()
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = pitch_scale
	player.position = position
	return player


func get_player_3d(position: Vector3) -> AudioStreamPlayer3D:
	var player := AudioStreamPlayer3D.new()
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = pitch_scale
	player.position = position
	return player
