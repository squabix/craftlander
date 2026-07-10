class_name InterpolatedBar
extends ProgressBar

@export_group("Interpolation")
@export_range(0.0, 1.0) var lerp_weight := 0.5
@export var jump_distance := 0.05

@export_group("Fade")
@export var fade_when_idle := false
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var fade_in_duration := 0.1
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var fade_out_duration := 0.1
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var idle_fade_wait_time := 2.0
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var initial_fade_in_suspension := 0.5
@export var fade_target_override: CanvasItem

var target_value := value:
	set(to):
		if is_equal_approx(target_value, to) or not passed_initial_fade_in_suspension() or not fade_when_idle:
			target_value = to
			return

		target_value = to
		show()

		# Kill active fade tween
		if _fade_tween != null and _fade_tween.is_valid():
			_fade_tween.kill()

		# Smoothly fade in to 1.0 alpha
		_fade_tween = create_tween()
		_fade_tween.tween_property(fade_target, "modulate:a", 1.0, fade_in_duration)

		# Create/Reset the idle timer
		_idle_timer = get_tree().create_timer(idle_fade_wait_time)

		# Connect it to the fade function (using a lambda)
		var current_timer := _idle_timer
		_idle_timer.timeout.connect(
			func():
				if current_timer == _idle_timer:
					_start_fade_out()
		)
var fade_target: CanvasItem
var _idle_timer: SceneTreeTimer
var _fade_tween: Tween
var _initial_time: float


func _ready() -> void:
	fade_target = fade_target_override if is_instance_valid(fade_target_override) else self
	target_value = value
	if fade_when_idle:
		fade_target.modulate.a = 0.0
		hide()
	_initial_time = Util.get_time_seconds()


func _process(_delta: float) -> void:
	value = lerp(value, target_value, lerp_weight)
	var distance: float = abs(value - target_value)
	if distance <= jump_distance:
		value = target_value


func passed_initial_fade_in_suspension() -> bool:
	return Util.get_time_seconds() - _initial_time >= initial_fade_in_suspension


func _start_fade_out() -> void:
	if _fade_tween and _fade_tween.is_valid():
		_fade_tween.kill()

	_fade_tween = create_tween()
	_fade_tween.tween_property(fade_target, "modulate:a", 0.0, fade_out_duration)
