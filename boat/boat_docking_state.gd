extends State

const SUCCESS_DISTANCE := 0.5

func enter() -> void:
	root.driver_seat.is_driver = false

func update(_delta: float) -> void:
	root.move_forward()
	if root.global_position.distance_to(root.dock_position) < SUCCESS_DISTANCE:
		transition_to("Docked")
