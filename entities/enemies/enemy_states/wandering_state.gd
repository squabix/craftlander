extends State

@export var nav_guide: NavEntityGuide3D
@export var min_idle_time := 1.0
@export var max_idle_time := 5.0
@export var inner_wander_radius := 4.0
@export var outter_wander_radius := 12.0
@export var idle_distance := 1.5
@export var idle_timer: Timer

var is_moving := false

func _ready() -> void:
	idle_timer.one_shot = true
	idle_timer.timeout.connect(start_moving)

func enter() -> void:
	start_idle_timer()

func start_idle_timer() -> void:
	if not is_active:
		return
	is_moving = false
	idle_timer.wait_time = randf_range(min_idle_time, max_idle_time)
	idle_timer.start()

func update(_delta: float) -> void:
	if is_moving:
		if root.global_position.distance_to(nav_guide.target_position) <= idle_distance:
			start_idle_timer()
		nav_guide.face_target()
		root.move_forward()

func start_moving() -> void:
	if not is_active:
		return
	nav_guide.set_target(
		nav_guide.get_nearby_navigable_position(
			root.global_position,
			inner_wander_radius,
			outter_wander_radius
		)
	)
	is_moving = true
