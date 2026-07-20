extends Save

var boat_level: int
var base_seed := 0

# Levels
var current_level_index := 0
var generated_levels := PackedInt32Array()

func mark_current_level_as_generated() -> void:
	if current_level_index in generated_levels:
		return
	generated_levels.append(current_level_index)

func is_current_level_generated() -> bool:
	return current_level_index in generated_levels
