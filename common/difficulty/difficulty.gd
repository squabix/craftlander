@abstract
class_name Difficulty
extends Object

const SETTINGS: DifficultySettings = preload("res://common/difficulty/default_difficulty_settings.tres")


static func get_display_name(value: int) -> String:
	return SETTINGS.display_names.get(value, str(value))


static func get_profile(profile_index: int) -> DifficultyProfile:
	if profile_index < 0 or profile_index >= SETTINGS.profiles.size():
		push_error("Difficulty: no profile configured at index %s" % profile_index)
		return null
	return SETTINGS.profiles[profile_index]


static func get_max_hp_multiplier(profile_index: int, value: int) -> float:
	var profile := get_profile(profile_index)
	if profile == null:
		return 1.0
	return lookup_multiplier(value, profile.max_hp_multipliers)


static func get_damage_taken_multiplier(profile_index: int, value: int) -> float:
	var profile := get_profile(profile_index)
	if profile == null:
		return 1.0
	return lookup_multiplier(value, profile.damage_taken_multipliers)


static func lookup_multiplier(value: int, table: Dictionary) -> float:
	if table.is_empty():
		push_error("Difficulty: no multipliers configured")
		return 1.0
	return table[clampi(value, table.keys().min(), table.keys().max())]


static func get_named_range() -> Vector2i:
	var keys := SETTINGS.display_names.keys()
	if keys.is_empty():
		return Vector2i.ZERO
	return Vector2i(keys.min(), keys.max())
