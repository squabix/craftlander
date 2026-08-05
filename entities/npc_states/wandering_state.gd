extends State

signal started
signal stopped

@export var nav_guide: NavEntityGuide3D
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var inner_wander_radius := 4.0
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var outter_wander_radius := 12.0
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var reach_distance := 1.5

@export_group("Idling")
@export var enable_idling := true
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var min_idle_time := 1.0
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var max_idle_time := 5.0
@export var idle_timer: Timer

var is_moving := false
var _reach_distance_sq: float


func _ready() -> void:
	_reach_distance_sq = reach_distance * reach_distance
	if enable_idling:
		idle_timer.one_shot = true
		idle_timer.timeout.connect(start_moving)


func enter() -> void:
	restart()


func start_idle_timer() -> void:
	if not is_active:
		return
	is_moving = false
	idle_timer.wait_time = randf_range(min_idle_time, max_idle_time)
	idle_timer.start()


func restart() -> void:
	is_moving = false
	if enable_idling:
		start_idle_timer()
		stopped.emit()
	else:
		start_moving()


func physics_update(_delta: float) -> void:
	if is_moving:
		# Using distance_squared_to to bypass slow square-root evaluations
		var distance_sq: float = root.global_position.distance_squared_to(nav_guide.target_position)
		if distance_sq <= _reach_distance_sq:
			restart()
			return

		nav_guide.face_target()
		nav_guide.entity.move_forward()


func start_moving() -> void:
	if not is_active:
		return
	nav_guide.set_target(
		nav_guide.get_nearby_navigable_position(
			inner_wander_radius,
			outter_wander_radius,
		),
	)
	is_moving = true
	started.emit()
