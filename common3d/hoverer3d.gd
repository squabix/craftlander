class_name Hoverer3D
extends RayCast3D

@export var target: Node3D

@export_group("Hover", "hover")
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var hover_height := 0.8
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var hover_min_clearance := 0.3
@export_custom(PROPERTY_HINT_NONE, "suffix:/s") var hover_follow_sharpness := 1.5

@export_group("Probe", "probe")
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var probe_height := 30.0
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var probe_depth := 80.0

@export_group("Height Bias", "bias")
@export_custom(PROPERTY_HINT_NONE, "suffix:m/s") var bias_speed := 1.0

var _bias_y := 0.0
var _bias_weight := 0.0


func _ready() -> void:
	top_level = true
	enabled = false
	target_position = Vector3.DOWN * (probe_height + probe_depth)


func _physics_process(delta: float) -> void:
	if not is_instance_valid(target):
		return

	if target is CharacterBody3D:
		target.velocity.y = 0.0
	global_transform = Transform3D(Basis.IDENTITY, target.global_position + Vector3.UP * probe_height)
	force_raycast_update()
	if not is_colliding():
		return

	var ground_y := get_collision_point().y
	var hover_y := ground_y + hover_height
	var followed_y := lerpf(
		target.global_position.y,
		hover_y,
		1.0 - exp(-hover_follow_sharpness * delta),
	)
	followed_y = _apply_bias(followed_y, hover_y, ground_y, delta)
	target.global_position.y = maxf(followed_y, ground_y + hover_min_clearance)


func set_height_bias(target_y: float, weight: float) -> void:
	_bias_y = target_y
	_bias_weight = clampf(weight, 0.0, 1.0)


func clear_height_bias() -> void:
	_bias_weight = 0.0


func _apply_bias(followed_y: float, hover_y: float, ground_y: float, delta: float) -> float:
	if _bias_weight <= 0.0:
		return followed_y
	var biased_y := maxf(_bias_y, ground_y + hover_min_clearance)
	var wanted_y := lerpf(hover_y, biased_y, _bias_weight)
	return move_toward(target.global_position.y, wanted_y, bias_speed * delta)
