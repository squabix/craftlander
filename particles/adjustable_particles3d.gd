class_name AdjustableParticles3D
extends GPUParticles3D

@export_custom(PROPERTY_HINT_NONE, "suffix:m") var base_radius := 1.0
@export var default_tint := Color.WHITE

var _tint_tween: Tween
var _fade_tween: Tween
var _follow_target: Node3D
var _follow_offset := Vector3.ZERO
var _stopping := false


func _ready() -> void:
	set_process(false)
	set_tint(default_tint)
	if one_shot:
		finished.connect(queue_free)


func _process(_delta: float) -> void:
	if not is_instance_valid(_follow_target):
		set_process(false)
		return
	global_position = _follow_target.global_position + _follow_offset


func set_radius(meters: float) -> void:
	if base_radius > 0.0:
		scale = Vector3.ONE * (meters / base_radius)


func set_tint(color: Color) -> void:
	var material := _get_local_material()
	if material != null:
		material.color = color


func tween_tint(color: Color, duration: float) -> void:
	var material := _get_local_material()
	if material == null:
		return
	if is_instance_valid(_tint_tween):
		_tint_tween.kill()
	_tint_tween = create_tween()
	_tint_tween.tween_property(material, ^"color", color, maxf(duration, 0.001))
	await _tint_tween.finished


func set_intensity(ratio: float) -> void:
	amount_ratio = clampf(ratio, 0.0, 1.0)


func follow(target: Node3D, offset := Vector3.ZERO) -> void:
	_follow_target = target
	_follow_offset = offset
	set_process(is_instance_valid(target))


func fade_out(duration: float) -> void:
	if _stopping:
		return
	if is_instance_valid(_fade_tween):
		_fade_tween.kill()
	_fade_tween = create_tween()
	_fade_tween.tween_property(self, ^"amount_ratio", 0.0, maxf(duration, 0.001))
	await _fade_tween.finished
	stop()


func stop() -> void:
	if _stopping:
		return
	_stopping = true
	emitting = false
	get_tree().create_timer(lifetime + 0.2, false).timeout.connect(queue_free)


func _get_local_material() -> ParticleProcessMaterial:
	var material := process_material as ParticleProcessMaterial
	if material == null:
		return null
	if not material.resource_local_to_scene:
		material = material.duplicate()
		material.resource_local_to_scene = true
		process_material = material
	return material
