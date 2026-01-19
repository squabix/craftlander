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
	if entity.global_position.distance_to(sight.target.global_position) > MIN_TARGET_DISTANCE:
		entity.move_forward()
