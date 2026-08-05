class_name SceneSpawner3D
extends Spawner3D

@export var scenes: Array[PackedScene]


func create_instance() -> Node3D:
	var scene := scenes.pick_random() as PackedScene
	if scene == null or not scene.can_instantiate():
		return null
	return scene.instantiate()
