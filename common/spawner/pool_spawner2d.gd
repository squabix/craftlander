extends Spawner2D
class_name PoolSpawner2D


@export var pool: Dictionary[PackedScene, float] = {} # PackedScene -> spawn chance

func get_scene() -> PackedScene:
	if pool.size() == 0:
		return default_scene
	
	var total_chance: float = 0.0
	for chance in pool.values():
		total_chance += chance
	
	var random_value: float = randf() * total_chance
	var accumulated_chance: float = 0.0
	
	for scene in pool.keys():
		accumulated_chance += pool[scene]
		if random_value < accumulated_chance:
			return scene
	
	return default_scene
