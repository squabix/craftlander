class_name MoveMode
extends Resource

@export_custom(PROPERTY_HINT_NONE, "suffix:m/s") var max_speed := Vector2(0, 0)
@export_custom(PROPERTY_HINT_NONE, "suffix:/s") var accelerate_sharpness := Vector2(15.0, 0.0)
@export_custom(PROPERTY_HINT_NONE, "suffix:/s")  var friction_sharpness := Vector2(20.0, 0.0)

@export_group("Acceleration Settings")
@export var instant_vertical_acceleration := true
@export_custom(PROPERTY_HINT_NONE, "suffix:m/s") var accelerate_threshold := 0.1


func _to_string() -> String:
	return "MoveMode (accelerate to %s with sharpness %s, friction sharpness of %s)" % [max_speed, accelerate_sharpness, friction_sharpness]


func move1d(velocity: float, direction: float, max_speed1d: float, accelerate_sharpness1d: float, friction_sharpness1d: float, delta: float) -> float:
	var rate: float
	var target_velocity: float

	if abs(direction) > accelerate_threshold and accelerate_sharpness1d > 0.0:
		rate = accelerate_sharpness1d
		target_velocity = direction * max_speed1d
	else:
		rate = friction_sharpness1d
		target_velocity = 0.0

	var lerp_weight = 1.0 - exp(-rate * delta)

	return lerp(velocity, target_velocity, lerp_weight)


func move2d(velocity: Vector2, direction: Vector2, delta: float) -> Vector2:
	return Vector2(
		move1d(
			velocity.x,
			direction.x,
			max_speed.x,
			accelerate_sharpness.x,
			friction_sharpness.x,
			delta,
		),
		move1d(
			velocity.y,
			direction.y,
			max_speed.y,
			INF if instant_vertical_acceleration else accelerate_sharpness.y,
			friction_sharpness.y,
			delta,
		),
	)


func move3d(velocity: Vector3, direction: Vector3, delta: float) -> Vector3:
	return Vector3(
		move1d(
			velocity.x,
			direction.x,
			max_speed.x,
			accelerate_sharpness.x,
			friction_sharpness.x,
			delta,
		),
		move1d(
			velocity.y,
			direction.y,
			max_speed.y,
			INF if instant_vertical_acceleration else accelerate_sharpness.y,
			friction_sharpness.y,
			delta,
		),
		move1d(
			velocity.z,
			direction.z,
			max_speed.x,
			accelerate_sharpness.x,
			friction_sharpness.x,
			delta,
		),
	)
