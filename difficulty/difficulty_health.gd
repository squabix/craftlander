class_name DifficultyHealth
extends Health

@export_group("Difficulty", "difficulty")
@export var difficulty_profile_index := 1


func _ready() -> void:
	super()
	Main.root.difficulty_changed.connect(_on_difficulty_changed)


func get_max_hp_multiplier() -> float:
	return Difficulty.get_max_hp_multiplier(difficulty_profile_index, Main.loaded_save.difficulty)


func get_damage_taken_multiplier() -> float:
	return Difficulty.get_damage_taken_multiplier(difficulty_profile_index, Main.loaded_save.difficulty)


func _on_difficulty_changed(_value: int) -> void:
	refresh_max_hp(false)
