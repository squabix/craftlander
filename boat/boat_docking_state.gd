extends State

const SUCCESS_DISTANCE := 0.2

@export var interactable: Interactable3D
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var timeout := 20.0

var dock_speed: float
var _elapsed := 0.0


func enter() -> void:
	if is_instance_valid(interactable):
		interactable.disable()
	root.driver_seat.is_driver = false
	dock_speed = root.move_mode.max_speed.x
	_elapsed = 0.0


func physics_update(delta: float) -> void:
	root.global_position = root.global_position.move_toward(root.dock_position, dock_speed * delta)


func update(delta: float) -> void:
	_elapsed += delta
	if root.global_position.distance_to(root.dock_position) >= SUCCESS_DISTANCE and _elapsed < timeout:
		return
	if _elapsed >= timeout:
		# Never leave a boat (and the wave spawner gated on it) stuck indefinitely
		Util.node_error("%s timed out docking; snapping to its dock point", root)
		root.global_position = root.dock_position
	transition_to(&"Docked")
