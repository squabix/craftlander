class_name CharacterAudioStreamPlayer3D
extends AudioStreamPlayer3D

@export var disabled := false
@export var character: CharacterBody3D
@export_custom(PROPERTY_HINT_NONE, "suffix:m/s") var min_speed := 0.1
@export_custom(PROPERTY_HINT_NONE, "suffix:m/s") var max_speed := 10.0
@export var only_on_floor := true
@export var vertical := false

@export_group("Interval", "interval")
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var interval_default_length := 0.4
@export var interval_curve: Curve
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var interval_variation := 0.0

var _time_since_last_play := 0.0
var _was_moving := false  # Track movement state across frames

func _physics_process(delta: float) -> void:
	if not is_instance_valid(character):
		set_physics_process(false)
		return
	
	if disabled:
		return
	
	if only_on_floor and not character.is_on_floor():
		stop()
		_time_since_last_play = 0.0
		_was_moving = false
		return
	
	var velocity := get_velocity()
	var speed := velocity.length()
	var is_moving := speed >= min_speed
	
	# Handle stopping/below min_speed
	if not is_moving:
		_time_since_last_play = 0.0
		_was_moving = false
		return

	# If the character just STARTED moving this frame
	if not _was_moving:
		play()
		_time_since_last_play = -randf_range(0.0, interval_variation)
		_was_moving = true
		return

	# Standard interval loop while moving continuously
	_time_since_last_play += delta
	
	if _time_since_last_play >= get_interval(speed):
		play()
		# Re-apply variation for subsequent intervals
		_time_since_last_play = -randf_range(0.0, interval_variation)

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
		return interval_default_length
		
	return interval_curve.sample(clampf(remap(speed, min_speed, max_speed, 0.0, 1.0), 0.0, 1.0))
