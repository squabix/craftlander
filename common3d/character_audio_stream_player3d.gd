class_name CharacterAudioStreamPlayer3D
extends AudioStreamPlayer3D

@export var character: CharacterBody3D
@export_custom(PROPERTY_HINT_NONE, "suffix:m/s") var min_speed := 0.1
@export_custom(PROPERTY_HINT_NONE, "suffix:m/s") var max_speed := 10.0
@export var only_on_floor := true
@export var vertical := false

@export_group("Interval")
@export var interval_curve: Curve
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var default_interval := 0.4

var _time_since_last_play := 0.0

func _physics_process(delta: float) -> void:
	if not is_instance_valid(character):
		set_physics_process(false)
		return
	
	if only_on_floor and not character.is_on_floor():
		stop()
		_time_since_last_play = 0.0
		return
	
	var velocity := get_velocity()
	var speed := velocity.length()
	
	if speed < min_speed:
		_time_since_last_play = 0.0
		return

	_time_since_last_play += delta
	
	if _time_since_last_play >= get_interval(speed):
		play()
		_time_since_last_play = 0.0

func get_velocity() -> Vector3:
	if not is_instance_valid(character):
		Util.node_error("%s cannot get velocity from invalid character", self)
		return Vector3.ZERO
	var velocity := character.velocity
	if not vertical:
		velocity.y = 0.0
	return velocity

func get_interval(speed: float) -> float:
	if interval_curve == null:
		return default_interval
		
	# Normalize speed between 0.0 and 1.0 based on min_speed and max_speed
	return interval_curve.sample(clampf(remap(speed, min_speed, max_speed, 0.0, 1.0), 0.0, 1.0))
