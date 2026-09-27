class_name CameraShakeTrigger
extends SignalTrigger

@export_range(0.0, 1.0, 0.01) var trauma := 0.1
@export var use_signal_position := false


func trigger(...args: Array) -> void:
	if disabled:
		return

	var at: Variant = args[0] if use_signal_position and args.size() > 0 else null
	CameraShake3D.shake(trauma, at)
