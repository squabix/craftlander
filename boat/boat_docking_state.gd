extends State

const SUCCESS_DISTANCE := 0.2

var dock_speed: float


func enter() -> void:
	root.driver_seat.is_driver = false
	dock_speed = root.movement_mode.max_speed.x


func physics_update(delta: float) -> void:
	root.global_position = root.global_position.move_toward(root.dock_position, dock_speed * delta)


func update(_delta: float):
	if root.global_position.distance_to(root.dock_position) < SUCCESS_DISTANCE:
		transition_to("Docked")
