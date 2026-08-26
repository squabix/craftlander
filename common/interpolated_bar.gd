class_name InterpolatedBar
extends ProgressBar

@export_group("Interpolation")
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var interpolation_duration := 0.25
@export var transition_type := Tween.TRANS_SINE
@export var ease_type := Tween.EASE_OUT

@export_group("Fade", "fade")
@export var fade_when_idle := false
@export_subgroup("Duration", "fade_duration")
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var fade_duration_in := 0.1
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var fade_duration_out := 0.1
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var fade_wait_time_idle := 5.0
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var fade_in_initial_suspension := 0.5
@export var fade_target_override: CanvasItem

var target_value := value:
	set(to):
		if is_equal_approx(target_value, to):
			return

		target_value = to
		_animate_value()
		_handle_fade()
var fade_target: CanvasItem
var _value_tween: Tween
var _fade_tween: Tween
var _idle_timer: SceneTreeTimer
var _initial_time: float


func _ready() -> void:
	# Disable step snapping so continuous float values can tween smoothly
	step = 0.0

	fade_target = fade_target_override if is_instance_valid(fade_target_override) else self
	target_value = value

	if fade_when_idle:
		fade_target.modulate.a = 0.0
		hide()

	_initial_time = Util.get_time_seconds()


func fill() -> void:
	target_value = max_value


func empty() -> void:
	target_value = min_value


func passed_initial_fade_in_suspension() -> bool:
	return Util.get_time_seconds() - _initial_time >= fade_in_initial_suspension


func _animate_value() -> void:
	if _value_tween and _value_tween.is_valid():
		_value_tween.kill()

	_value_tween = create_tween().set_trans(transition_type).set_ease(ease_type)
	_value_tween.tween_property(self, "value", target_value, interpolation_duration)


func _handle_fade() -> void:
	if not fade_when_idle or not passed_initial_fade_in_suspension():
		return

	show()

	if _fade_tween and _fade_tween.is_valid():
		_fade_tween.kill()

	_fade_tween = create_tween()
	_fade_tween.tween_property(fade_target, "modulate:a", 1.0, fade_duration_in)

	_idle_timer = get_tree().create_timer(fade_wait_time_idle)
	var current_timer := _idle_timer
	_idle_timer.timeout.connect(
		func():
			if current_timer == _idle_timer:
				_start_fade_out()
	)


func _start_fade_out() -> void:
	if _fade_tween and _fade_tween.is_valid():
		_fade_tween.kill()

	_fade_tween = create_tween()
	_fade_tween.tween_property(fade_target, "modulate:a", 0.0, fade_duration_out)
