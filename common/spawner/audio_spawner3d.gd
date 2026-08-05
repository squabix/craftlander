class_name AudioSpawner3D
extends Duplicator3D

@export var autoplay := true
@export var one_shot := true

@export_group("Player Override", "override")
@export var override_stream: AudioStream
@export var override_bus := &"Master"
@export_range(-80.0, 80.0, 0.001, "suffix:dB") var override_volume_db := 0.0
@export var override_pitch_scale := 1.0


static func play_one_shot(player: AudioStreamPlayer3D) -> void:
	if not is_instance_valid(player):
		return
	player.play()
	await player.finished
	Util.safe_free(player)


func create_instance() -> Node3D:
	if override_stream == null:
		return super()
		
	var new_player := AudioStreamPlayer3D.new()
	new_player.stream = override_stream
	new_player.bus = override_bus
	new_player.volume_db = override_volume_db
	new_player.max_db = override_volume_db
	new_player.pitch_scale = override_pitch_scale
	return new_player


func initialize_instance(instance: Node3D) -> void:
	super(instance)
	
	var player := instance as AudioStreamPlayer3D
	if not is_instance_valid(player):
		Util.node_error("%s cannot initialize an instance that is not an AudioStreamPlayer3D", self)
		return

	if autoplay:
		if one_shot:
			AudioSpawner3D.play_one_shot(player)
		else:
			player.play()
