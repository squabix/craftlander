class_name CaptainLullState
extends LullState

const LINE := &"breathe"

var captain: GhostCaptain:
	get:
		return root as GhostCaptain


func get_interrupt() -> StringName:
	return &"PhaseBreak" if captain.is_phase_due() else &""


func has_target() -> bool:
	return captain.get_player() != null


func on_lull() -> void:
	captain.voice.say(LINE)


func get_gap() -> float:
	return gap * captain.recovery_scale()
