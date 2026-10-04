class_name DifficultyWaveSpawner3D
extends WaveSpawner3D

@export_group("Difficulty", "difficulty")
@export var difficulty_profile_index := 1


func get_concurrent_limit() -> int:
	if max_concurrent_instances <= 0:
		return max_concurrent_instances

	var multiplier := Difficulty.get_concurrent_enemies_multiplier(difficulty_profile_index, Main.loaded_save.difficulty)
	return maxi(1, roundi(max_concurrent_instances * multiplier))
