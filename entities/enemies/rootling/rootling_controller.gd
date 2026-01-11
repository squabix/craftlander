extends Controller3D

const MIN_TARGET_DISTANCE := 1.5

@export var sight: RadialSight3D

func _process(_delta: float) -> void:
	if not sight.does_see_target():
		return
	entity.look_at(sight.target_position)
	if entity.global_position.distance_to(sight.target.global_position) > MIN_TARGET_DISTANCE:
		entity.move_forward()
