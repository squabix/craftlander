class_name GhostBoat
extends Boat

const SINK_DEPTH := 6.0

@export var spawner: Spawner3D
@export var cannon: GhostCannon

var _sinking := false


func sink(duration := 3.0) -> void:
	if _sinking:
		return
	_sinking = true
	
	if is_instance_valid(cannon):
		cannon.set_active(false)
	
	var tween := create_tween()
	tween.tween_property(self, ^"global_position:y", global_position.y - SINK_DEPTH, duration)
	tween.tween_callback(queue_free)
