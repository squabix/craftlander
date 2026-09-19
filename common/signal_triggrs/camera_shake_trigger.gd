class_name CameraShakeTrigger
extends SignalTrigger

@export_range(0.0, 1.0, 0.01) var trauma := 0.1


func trigger(..._args: Array) -> void:
	if disabled:
		return

	CameraShake3D.shake(trauma)
