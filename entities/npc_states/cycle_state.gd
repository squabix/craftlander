class_name CycleState
extends SequenceState

@export var cycles: Array[PackedStringArray] # state names per phase
@export var phase_property := &"phase"

var _index := 0
var _last_phase := 0


func run() -> void:
	var phase: int = root.get(phase_property)
	if phase != _last_phase:
		_last_phase = phase
		_index = 0

	var cycle := cycles[clampi(phase, 0, cycles.size() - 1)]
	var next := cycle[_index % cycle.size()]
	_index += 1
	go_to(StringName(next))
