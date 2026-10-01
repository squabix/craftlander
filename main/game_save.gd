extends Save
class_name GameSave

const TAG_CAPTAIN_DEFEATED := &"captain_defeated"
const TAG_GAME_BEATEN := &"game_beaten"

@export var boat_level: int
@export var base_seed := 0
@export var difficulty: int = Difficulty.SETTINGS.default_value

# Levels
@export var current_level_index := 0
@export var generated_levels := PackedInt32Array()

# Tutorial
@export var tutorial_steps_completed: Dictionary[StringName, bool]


static func is_captain_defeated() -> bool:
	var save := Main.loaded_save as GameSave
	return save != null and save.is_tagged(TAG_CAPTAIN_DEFEATED)


static func is_game_beaten() -> bool:
	var save := Main.loaded_save as GameSave
	return save != null and save.is_tagged(TAG_GAME_BEATEN)


static func mark_captain_defeated() -> void:
	var save := Main.loaded_save as GameSave
	if save != null:
		save.add_tag(TAG_CAPTAIN_DEFEATED)


static func mark_game_beaten() -> void:
	var save := Main.loaded_save as GameSave
	if save != null:
		save.add_tag(TAG_GAME_BEATEN)


func mark_current_level_as_generated() -> void:
	if current_level_index in generated_levels:
		return
	generated_levels.append(current_level_index)

func forget_level_generation(level_index: int) -> void:
	var position := generated_levels.find(level_index)
	if position >= 0:
		generated_levels.remove_at(position)


func is_current_level_generated() -> bool:
	return current_level_index in generated_levels
