extends Node

var muted := false

func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS

func mute() -> void:
	muted = true

func unmute() -> void:
	muted = false

func loop(sound: Sound, count: int=-1) -> void:
	if count < 0:
		await play(sound)
		loop(sound)
	elif count > 0:
		await play(sound)
		loop(sound)
		count -= 1
	else:
		return

func play(sound: Sound) -> void:
	if muted or not sound:
		return
	
	var player := sound.get_player()
	add_child(player)
	player.play()
	
	await player.finished
	Util.safe_free(player)

func play2d(sound: Sound, position: Vector2) -> void:
	if muted:
		return
	
	var player: AudioStreamPlayer2D = sound.get_player_2d(position)
	add_child(player)
	player.play()
	
	await player.finished
	Util.safe_free(player)

func play3d(sound: Sound, position: Vector3) -> void:
	if muted:
		return
	
	var player: AudioStreamPlayer3D = sound.get_player_3d(position)
	add_child(player)
	player.play()
	
	await player.finished
	Util.safe_free(player)
