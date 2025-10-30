extends Timer
class_name RandomTimer

@export var variation: float = 0.0

var base_wait_time: float

func _ready() -> void:
	base_wait_time = wait_time
	timeout.connect(randomize_time)

func randomize_time() -> void:
	wait_time = base_wait_time + randf_range(0.0, variation)