class_name MovementMode
extends Resource

## The minimum direction magnitude before interpolating via acceleration instead of friction
@export var accelerate_threshold: float = 0.1


func accel_axis(velocity: float, direction: float, speed: float, acceleration: float, friction: float, delta: float) -> float:
	var rate: float
	var target_velocity: float

	if abs(direction) > accelerate_threshold and acceleration > 0.0:
		rate = acceleration
		target_velocity = direction * speed
	else:
		rate = friction
		target_velocity = 0.0

	var lerp_weight = 1.0 - exp(-rate * delta)

	return lerp(velocity, target_velocity, lerp_weight)
