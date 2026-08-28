extends Save
class_name GameSave

@export var boat_level: int
@export var base_seed := 0
@export var difficulty: int = Difficulty.SETTINGS.default_value

# Levels
@export var current_level_index := 0
@export var generated_levels := PackedInt32Array()
@export var sky_setting: SkySetting = preload("res://island/skies/initial_sky_setting.tres")

func mark_current_level_as_generated() -> void:
	if current_level_index in generated_levels:
		return
	generated_levels.append(current_level_index)

func is_current_level_generated() -> bool:
	return current_level_index in generated_levels
