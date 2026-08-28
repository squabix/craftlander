class_name WaveDisplay3D
extends Control

@export var wave_spawner: WaveSpawner3D
@export var interpolated_bar: InterpolatedBar
@export var name_label: Label

@export_group("Default Name", "default_name")
@export var default_name_format := "Wave %s"
@export var default_name_index_offset := 1

var active := false
var current_wave: WaveSpawnerWave

func _ready() -> void:
	update()
	if not is_instance_valid(wave_spawner):
		Util.node_error("%s will not work without wave spawner", self)
		return
	
	wave_spawner.wave_started.connect(set_wave)
	wave_spawner.entity_despawned.connect(update)
	wave_spawner.finished.connect(deactivate)

func update() -> void:
	
	visible = active
	if is_instance_valid(interpolated_bar):
		interpolated_bar.target_value = wave_spawner.get_total_remaining_count()
	if is_instance_valid(name_label) and current_wave != null:
		name_label.text = (
			String(current_wave.name) if not current_wave.name.is_empty()
			else default_name_format % (wave_spawner.current_wave_index + 1)
		)

func set_wave(index: int) -> void:
	var new_wave := wave_spawner.get_wave(index)
	if new_wave == null:
		return
	
	current_wave = new_wave
	activate()
	
	update()
	
	if is_instance_valid(interpolated_bar):
		interpolated_bar.max_value = WaveSpawner3D.count_pool(current_wave.pool)
		interpolated_bar.value = interpolated_bar.max_value
		interpolated_bar.target_value = interpolated_bar.value

func activate() -> void:
	active = true

func deactivate() -> void:
	active = false
