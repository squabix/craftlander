class_name Cutscene3D
extends Node

signal began
signal ended

@export var camera: Camera3D
@export var subject: Node3D
@export var subject_camera: Camera3D
@export var hide_group: StringName
@export var fade_layer := 10

@export_group("Letterbox", "letterbox")
@export var letterbox_enabled := false
@export var letterbox_layer := 100
@export_range(0.0, 0.5) var letterbox_size := 0.12
@export var letterbox_color := Color.BLACK
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var letterbox_slide_time := 0.5

var is_playing := false

var _previous_camera: Camera3D
var _tweens: Array[Tween] = []
var _hidden_nodes: Array[Node] = []
var _letterbox_overlay: Control
var _fade_overlay: Control
var _letterbox_amount := 0.0
var _letterbox_tween: Tween
var _fade_color := Color(0.0, 0.0, 0.0, 0.0)
var _fade_tween: Tween
var _time_scale_before := 1.0
var _time_scale_changed := false


func begin(lift := 0.0, ease_in_duration := 0.4) -> void:
	if not is_inside_tree() or not is_instance_valid(subject_camera):
		return

	if _previous_camera == null:
		_previous_camera = get_viewport().get_camera_3d()

	is_playing = true
	cut_to_subject()
	camera.make_current()
	_hide_group_nodes()
	if letterbox_enabled:
		set_letterbox(true)

	began.emit()
	if lift == 0.0 or ease_in_duration <= 0.0:
		camera.global_position += Vector3.UP * lift
		return

	var destination := camera.global_position + Vector3.UP * lift
	var tween := _new_tween()
	tween.tween_property(camera, ^"global_position", destination, ease_in_duration)
	await tween.finished


func end() -> void:
	if not is_playing:
		return
	is_playing = false
	_kill_tweens()
	camera.h_offset = 0.0
	camera.v_offset = 0.0
	_restore_time_scale()
	_restore_group_nodes()
	if _letterbox_amount > 0.0:
		set_letterbox(false)
	ended.emit()
	if is_instance_valid(_previous_camera):
		_previous_camera.make_current()
	else:
		subject_camera.make_current()
	_previous_camera = null


func cut_to(target: Transform3D) -> void:
	camera.global_transform = target


func cut_to_subject() -> void:
	camera.global_transform = subject_camera.global_transform
	camera.fov = subject_camera.fov
	camera.cull_mask = subject_camera.cull_mask


func set_frame(position: Vector3, look_point: Vector3) -> void:
	camera.global_position = position
	camera.look_at(look_point, Vector3.UP)


func face_subject(point: Vector3) -> void:
	if not is_instance_valid(subject):
		return
	var flat := point - subject.global_position
	flat.y = 0.0
	if flat.length_squared() > 0.001:
		subject.look_at(subject.global_position + flat, Vector3.UP)


func wait(seconds: float) -> void:
	await get_tree().create_timer(seconds, true, false, true).timeout


func move_to(position: Vector3, duration: float) -> void:
	var tween := _new_tween()
	tween.tween_property(camera, ^"global_position", position, duration)
	await tween.finished


func zoom_to(fov: float, duration: float) -> void:
	var tween := _new_tween()
	tween.tween_property(camera, ^"fov", fov, duration)
	await tween.finished


func move_look_zoom(position: Vector3, look_point: Vector3, fov: float, duration: float) -> void:
	if position.is_equal_approx(look_point):
		return
	var start_position := camera.global_position
	var start_rotation := camera.global_basis.get_rotation_quaternion()
	var start_fov := camera.fov
	var target_rotation := Transform3D(Basis.IDENTITY, position).looking_at(look_point, Vector3.UP).basis.get_rotation_quaternion()
	var tween := _new_tween()
	tween.tween_method(
		func(fraction: float) -> void:
			camera.global_position = start_position.lerp(position, fraction)
			camera.global_basis = Basis(start_rotation.slerp(target_rotation, fraction))
			camera.fov = lerpf(start_fov, fov, fraction),
		0.0,
		1.0,
		duration,
	)
	await tween.finished


func track(target: Node3D, duration: float) -> void:
	var elapsed := 0.0
	while elapsed < duration and is_playing and is_instance_valid(target) and is_inside_tree():
		camera.look_at(target.global_position, Vector3.UP)
		await get_tree().process_frame
		elapsed += get_process_delta_time()


func orbit(center: Vector3, degrees: float, duration: float, radius := -1.0) -> void:
	var offset := camera.global_position - center
	var flat := Vector2(offset.x, offset.z)
	var distance := flat.length() if radius < 0.0 else radius
	if distance < 0.001:
		return
	var height := offset.y
	var start_angle := flat.angle()
	var tween := _new_tween(Tween.TRANS_SINE)
	tween.tween_method(
		func(angle: float) -> void:
			camera.global_position = center + Vector3(cos(angle) * distance, height, sin(angle) * distance)
			camera.look_at(center, Vector3.UP),
		start_angle,
		start_angle + deg_to_rad(degrees),
		duration,
	)
	await tween.finished


func follow_path(path: Path3D, duration: float, look_target: Node3D = null) -> void:
	if not is_instance_valid(path) or path.curve == null or path.curve.get_baked_length() <= 0.0:
		return
	var curve := path.curve
	var length := curve.get_baked_length()
	var tween := _new_tween(Tween.TRANS_SINE)
	tween.tween_method(
		func(fraction: float) -> void:
			var offset := fraction * length
			var point := path.global_transform * curve.sample_baked(offset)
			camera.global_position = point
			if is_instance_valid(look_target):
				camera.look_at(look_target.global_position, Vector3.UP)
				return
			var ahead := path.global_transform * curve.sample_baked(minf(offset + 0.5, length))
			if ahead.distance_squared_to(point) > 0.0001:
				camera.look_at(ahead, Vector3.UP),
		0.0,
		1.0,
		duration,
	)
	await tween.finished


func shake(strength: float, duration: float) -> void:
	var tween := _new_tween(Tween.TRANS_LINEAR)
	tween.tween_method(
		func(fraction: float) -> void:
			var amount := strength * (1.0 - fraction)
			camera.h_offset = randf_range(-amount, amount)
			camera.v_offset = randf_range(-amount, amount),
		0.0,
		1.0,
		duration,
	)
	tween.tween_callback(
		func() -> void:
			camera.h_offset = 0.0
			camera.v_offset = 0.0
	)
	await tween.finished


func set_time_scale(time_scale: float, duration := 0.0) -> void:
	if not _time_scale_changed:
		_time_scale_before = Engine.time_scale
		_time_scale_changed = true
	if duration <= 0.0:
		Engine.time_scale = time_scale
		return
	var tween := _new_tween(Tween.TRANS_LINEAR).set_ignore_time_scale(true)
	tween.tween_property(Engine, ^"time_scale", time_scale, duration)
	await tween.finished


func set_letterbox(on: bool, duration := -1.0) -> void:
	_ensure_letterbox_overlay()
	if is_instance_valid(_letterbox_tween):
		_letterbox_tween.kill()
	var slide := letterbox_slide_time if duration < 0.0 else duration
	_letterbox_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	_letterbox_tween.tween_method(_set_letterbox_amount, _letterbox_amount, 1.0 if on else 0.0, maxf(slide, 0.001))
	await _letterbox_tween.finished


func fade_out(color := Color.BLACK, duration := 1.0) -> void:
	_ensure_fade_overlay()
	_fade_color = Color(color.r, color.g, color.b, _fade_color.a)
	await _tween_fade(1.0, duration)


func fade_in(duration := 1.0) -> void:
	_ensure_fade_overlay()
	await _tween_fade(0.0, duration)


func plan_sweep(origin: Vector3, points: Array[Vector3]) -> SweepPlan:
	var yaws: Array[float] = []
	var pitches: Array[float] = []

	for point in points:
		var offset := point - origin
		yaws.append(fposmod(atan2(-offset.x, -offset.z), TAU))
		pitches.append(atan2(offset.y, Vector2(offset.x, offset.z).length()))

	var widest_gap := _find_widest_gap(yaws)

	var plan := SweepPlan.new()
	plan.start_yaw = widest_gap.start_yaw
	plan.span = TAU - widest_gap.size if widest_gap.size > 0.0 else 0.0
	for yaw in yaws:
		var behind := fposmod(plan.start_yaw - yaw, TAU)
		plan.fractions.append(minf(behind / plan.span, 1.0) if plan.span > 0.001 else 0.0)
	plan.pitches = pitches
	return plan


func sweep(plan: SweepPlan, duration: float) -> void:
	camera.global_rotation = Vector3(plan.pitch_at(0.0), plan.start_yaw, 0.0)
	var from_yaw := camera.global_rotation.y
	var tween := _new_tween(Tween.TRANS_LINEAR)
	tween.tween_method(
		func(fraction: float) -> void:
			camera.global_rotation = Vector3(plan.pitch_at(fraction), from_yaw - plan.span * fraction, 0.0),
		0.0,
		1.0,
		duration,
	)
	await tween.finished


func look_toward(point: Vector3, duration: float) -> void:
	var offset := point - camera.global_position
	var target_yaw := camera.global_rotation.y + angle_difference(camera.global_rotation.y, atan2(-offset.x, -offset.z))
	var target_pitch := atan2(offset.y, Vector2(offset.x, offset.z).length())
	var tween := _new_tween().set_parallel(true)
	tween.tween_property(camera, ^"global_rotation:y", target_yaw, duration)
	tween.tween_property(camera, ^"global_rotation:x", target_pitch, duration)
	await tween.finished


func blend_back(duration: float) -> void:
	var tween := _new_tween()
	tween.tween_property(camera, ^"global_transform", subject_camera.global_transform, duration)
	await tween.finished
	end()


func _new_tween(trans := Tween.TRANS_CUBIC, ease_type := Tween.EASE_IN_OUT) -> Tween:
	_tweens = _tweens.filter(func(tween: Tween) -> bool: return tween.is_valid())
	var tween := create_tween().set_trans(trans).set_ease(ease_type)
	_tweens.append(tween)
	return tween


func _kill_tweens() -> void:
	for tween in _tweens:
		if tween.is_valid():
			tween.kill()
	_tweens.clear()


func _restore_time_scale() -> void:
	if _time_scale_changed:
		Engine.time_scale = _time_scale_before
		_time_scale_changed = false


func _hide_group_nodes() -> void:
	if hide_group.is_empty() or not _hidden_nodes.is_empty():
		return
	for node in get_tree().get_nodes_in_group(hide_group):
		if "visible" in node and node.visible:
			node.visible = false
			_hidden_nodes.append(node)


func _restore_group_nodes() -> void:
	for node in _hidden_nodes:
		if is_instance_valid(node):
			node.visible = true
	_hidden_nodes.clear()


func _ensure_letterbox_overlay() -> void:
	if not is_instance_valid(_letterbox_overlay):
		_letterbox_overlay = _create_overlay(letterbox_layer, _draw_letterbox)


func _ensure_fade_overlay() -> void:
	if not is_instance_valid(_fade_overlay):
		_fade_overlay = _create_overlay(fade_layer, _draw_fade)


func _create_overlay(layer_index: int, draw_callback: Callable) -> Control:
	var layer := CanvasLayer.new()
	layer.layer = layer_index
	var overlay := Control.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.draw.connect(draw_callback)
	layer.add_child(overlay)
	add_child(layer)
	return overlay


func _draw_letterbox() -> void:
	var bar_height := _letterbox_overlay.size.y * letterbox_size * _letterbox_amount
	if bar_height <= 0.0:
		return
	_letterbox_overlay.draw_rect(Rect2(0.0, 0.0, _letterbox_overlay.size.x, bar_height), letterbox_color)
	_letterbox_overlay.draw_rect(Rect2(0.0, _letterbox_overlay.size.y - bar_height, _letterbox_overlay.size.x, bar_height), letterbox_color)


func _draw_fade() -> void:
	if _fade_color.a > 0.0:
		_fade_overlay.draw_rect(Rect2(Vector2.ZERO, _fade_overlay.size), _fade_color)


func _set_letterbox_amount(amount: float) -> void:
	_letterbox_amount = amount
	_letterbox_overlay.queue_redraw()


func _tween_fade(target_alpha: float, duration: float) -> void:
	if is_instance_valid(_fade_tween):
		_fade_tween.kill()
	_fade_tween = create_tween().set_ignore_time_scale(true)
	_fade_tween.tween_method(_set_fade_alpha, _fade_color.a, target_alpha, maxf(duration, 0.001))
	await _fade_tween.finished


func _set_fade_alpha(alpha: float) -> void:
	_fade_color.a = alpha
	_fade_overlay.queue_redraw()


# Starts on the far side of the widest gap between points, so the sweep crosses it first
func _find_widest_gap(yaws: Array[float]) -> Dictionary:
	var sorted := yaws.duplicate()
	sorted.sort()
	var widest_size := -1.0
	var widest_start: float = sorted[0]
	for i in sorted.size():
		var gap := TAU if sorted.size() == 1 else fposmod(sorted[(i + 1) % sorted.size()] - sorted[i], TAU)
		if gap > widest_size:
			widest_size = gap
			widest_start = sorted[i]
	return { "start_yaw": widest_start, "size": widest_size }


class SweepPlan:
	var start_yaw := 0.0
	var span := 0.0
	var fractions: Array[float] = []
	var pitches: Array[float] = []


	# Interpolates between each point's own pitch so the camera tilts to each one as it passes
	func pitch_at(fraction: float) -> float:
		if pitches.is_empty():
			return 0.0
		var order: Array[int] = []
		for i in fractions.size():
			order.append(i)
		order.sort_custom(func(a: int, b: int) -> bool: return fractions[a] < fractions[b])
		if fraction <= fractions[order[0]]:
			return pitches[order[0]]
		for i in range(1, order.size()):
			var low := order[i - 1]
			var high := order[i]
			if fraction <= fractions[high]:
				var width := fractions[high] - fractions[low]
				if width < 0.0001:
					return pitches[high]
				return lerpf(pitches[low], pitches[high], (fraction - fractions[low]) / width)
		return pitches[order[-1]]
