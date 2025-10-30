extends MovementMode
class_name MovementMode3D

@export var max_speed: Vector2 = Vector2(0, 0)
@export var acceleration: Vector2 = Vector2(1, 1)
@export var friction: Vector2 = Vector2(1, 0)

func accel(velocity: Vector3, direction: Vector3) -> Vector3:
	return Vector3(
		accel_axis(velocity.x, direction.x, max_speed.x, acceleration.x, friction.x),
		accel_axis(velocity.y, direction.y, max_speed.y, acceleration.y, friction.y),
		accel_axis(velocity.z, direction.z, max_speed.x, acceleration.x, friction.x)
	)

func _to_string() -> String:
	return "MovementMode3D (accelerate to " + str(max_speed) + " by " + str(acceleration) + ", friction of " + str(friction) + ")"
