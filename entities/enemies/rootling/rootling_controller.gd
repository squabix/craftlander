extends Controller3D

const MIN_TARGET_DISTANCE := 2.0

@export var sight: RadialSight3D
@export var on_screen_notifier: VisibleOnScreenNotifier3D

@onready var guide: NavEntityGuide3D = $NavEntityGuide3D

func _process(_delta: float) -> void:
	if on_screen_notifier.is_on_screen():
		entity.show()
	else:
		entity.hide()
		if not sight.does_see_target():
			return
		
	if not sight.does_see_target():
		return
	
	guide.set_target(sight.target_position)
	
	guide.face_target()
	if is_target_far():
		entity.move_forward()

func is_target_far() -> bool:
	var v1 := Util.vec3to2(entity.global_position, Util.VECTOR3Y)
	var v2 := Util.vec3to2(sight.target.global_position, Util.VECTOR3Y)
	return v1.distance_to(v2) > MIN_TARGET_DISTANCE
