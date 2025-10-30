extends Resource
class_name MovementMode
## The minimum direction magnitude before interpolating via acceleration instead of friction
@export var accelerate_threshold: float = 0.1


func accel_axis(velocity: float, direction: float, speed: float, acceleration: float, friction: float) -> float:
	var lerp_weight: float
	var target_velocity: float
	
	if abs(direction) > accelerate_threshold and acceleration > 0.0:
		lerp_weight = acceleration
		target_velocity = direction * speed
	else:
		lerp_weight = friction
		target_velocity = 0.0
	
	return lerp(velocity, target_velocity, lerp_weight)
