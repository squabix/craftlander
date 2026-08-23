class_name WaveSpawnerWave
extends Resource

enum SceneSelectMode { SEQUENTIAL, UNWEIGTED, WEIGHTED }
enum SpawnerDistribution { SINGLE_ROUND_ROBIN, SINGLE_RANDOM, BATCH_SIMULTANEOUS }

@export var name := &""
@export var pool: Dictionary[PackedScene, int]

@export_group("Spawning")
@export var scene_select_mode := SceneSelectMode.WEIGHTED
@export var spawner_select_mode := MultiSpawner3D.SelectMode.ALL
@export var spawner_distribution := SpawnerDistribution.SINGLE_ROUND_ROBIN
@export var spawner_select_index_override := -1

@export_group("Pause Lengths")
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var pause_length_between_spawns := 1.0
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var pause_length_begin := 1.0
