class_name InterpolatedBar
extends ProgressBar

@export_group("Interpolation")
@export_range(0.0, 1.0) var lerp_weight := 0.5
@export var jump_distance := 0.05

@export_group("Fade")
@export var fade_when_idle := false
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var idle_fade_wait_time := 2.0
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var fade_in_duration := 0.1
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var fade_out_duration := 0.1

var target_value := value:
	set(to):
		if is_equal_approx(target_value, to):
			target_value = to
			return
		
		target_value = to
		
		if not fade_when_idle:
			return
		
		# Kill any active fade-out or fade-in tweens
		if _fade_tween and _fade_tween.is_valid():
			_fade_tween.kill()
		
		# Smoothly fade in to 1.0 alpha
		_fade_tween = create_tween()
		_fade_tween.tween_property(self, "modulate:a", 1.0, fade_in_duration)
		
		# Create/Reset the idle timer
		_idle_timer = get_tree().create_timer(idle_fade_wait_time)
		
		# Connect it to the fade function (using a lambda)
		var current_timer := _idle_timer
		_idle_timer.timeout.connect(
			func():
				if current_timer == _idle_timer:
					_start_fade_out()
		)
var _idle_timer: SceneTreeTimer
var _fade_tween: Tween


func _ready() -> void:
	target_value = value
	if fade_when_idle:
		modulate.a = 0.0


func _process(_delta: float) -> void:
	value = lerp(value, target_value, lerp_weight)
	var distance: float = abs(value - target_value)
	if distance <= jump_distance:
		value = target_value


func _start_fade_out() -> void:
	if _fade_tween and _fade_tween.is_valid():
		_fade_tween.kill()

	_fade_tween = create_tween()
	_fade_tween.tween_property(self, "modulate:a", 0.0, fade_out_duration)
