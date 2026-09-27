class_name CaptainComboState
extends ComboAttackState

@export var phase_swings: Array[int] = [2, 2, 3]

var captain: GhostCaptain:
	get:
		return root as GhostCaptain


func get_swing_count() -> int:
	return phase_swings[captain.phase]
