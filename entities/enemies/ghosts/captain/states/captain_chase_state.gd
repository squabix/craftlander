class_name CaptainChaseState
extends ChaseToRangeState

const LINE := &"chase"

var captain: GhostCaptain:
	get:
		return root as GhostCaptain


func enter() -> void:
	super()
	captain.voice.say(LINE)


func get_distance() -> float:
	return captain.distance_to_target()
