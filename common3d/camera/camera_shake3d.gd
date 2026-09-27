class_name CameraShake3D
extends Node

@export var camera: Camera3D

@export_group("Shake")
@export var max_position_offset := Vector2(0.15, 0.12)
@export_custom(PROPERTY_HINT_NONE, "suffix:°") var max_roll_degrees := 8.0
@export_custom(PROPERTY_HINT_NONE, "suffix:°") var max_yaw_degrees := 5.0
@export_custom(PROPERTY_HINT_NONE, "suffix:/s") var trauma_decay := 1.5
@export var trauma_exponent := 2.0
@export_custom(PROPERTY_HINT_NONE, "suffix:cycles/s") var shake_speed := 18.0

static var current: CameraShake3D
static var max_distance := 15.0 # m

var trauma := 0.0

var noise := FastNoiseLite.new()
var _time_offset := 0.0


static func shake(amount: float, at: Variant = null) -> void:
	if not is_instance_valid(current):
		return

	if at is Vector3 and is_instance_valid(current.camera):
		var distance := current.camera.global_position.distance_to(at)
		if distance >= max_distance:
			return
		amount *= 1.0 - distance / max_distance

	current.add_trauma(amount)


func _ready() -> void:
	current = self
	noise.seed = randi()
	noise.frequency = 1.0
	_time_offset = randf() * 1000.0


func _process(delta: float) -> void:
	if not is_instance_valid(camera):
		return

	if trauma > 0.0:
		trauma = max(trauma - trauma_decay * delta, 0.0)

	var shake_power := pow(trauma, trauma_exponent)
	var time := _time_offset + Time.get_ticks_msec() / 1000.0 * shake_speed
	camera.position.x = noise.get_noise_2d(time, 0.0) * shake_power * max_position_offset.x
	camera.position.y = noise.get_noise_2d(time, 100.0) * shake_power * max_position_offset.y
	camera.rotation_degrees.y = noise.get_noise_2d(time, 200.0) * shake_power * max_yaw_degrees
	camera.rotation_degrees.z = noise.get_noise_2d(time, 300.0) * shake_power * max_roll_degrees


func add_trauma(amount: float) -> void:
	if not GameSettings.config.get_value("gameplay", "screen_shake_enabled", true):
		return
	trauma = clamp(trauma + amount, 0.0, 1.0)
