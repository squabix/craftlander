class_name AudioSpawner3D
extends Spawner3D

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

func spawn(custom_scene: PackedScene = null, parent: Node = null) -> Node3D:
	if not is_instance_valid(parent):
		parent = get_default_parent()
		if not is_instance_valid(parent):
			return
	

	var spawn_position: Vector3 = get_spawn_position(parent)
	var spawn_rotation_degrees: Vector3 = get_spawn_rotation_degrees(parent)

	var scene := custom_scene if custom_scene != null else get_scene()
	
	var player: AudioStreamPlayer3D
	
	if override_stream == null:
		player = Spawner3D.spawn_at(
			spawn_position, # Spawn position
			spawn_rotation_degrees, # Spawn rotation
			scene, # Scene
			parent, # Parent
			initialize_instance, # Initializer
		) as AudioStreamPlayer3D
		if not is_instance_valid(player):
			Util.node_error("%s cannot spawn non-AudioStreamPlayer3D scene: %s", self, scene)
			return null
	else:
		player = AudioStreamPlayer3D.new()
		parent.add_child.call_deferred(player)
		player.stream = override_stream
		player.bus = override_bus
		player.volume_db = override_volume_db
		player.pitch_scale = override_pitch_scale
		initialize_instance(player)
	
	if autoplay:
		if one_shot:
			AudioSpawner3D.play_one_shot.call_deferred(player)
		else:
			player.play.call_deferred()
	
	spawned.emit(player)
	return player
