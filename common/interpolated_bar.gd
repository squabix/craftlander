extends ProgressBar
class_name InterpolatedBar

@export_range(0.0, 1.0) var lerp_weight := 0.5
@export var jump_distance := 0.05

var target_value := value

func _process(_delta: float) -> void:
	value = lerp(value, target_value, lerp_weight)
	var distance: float = abs(value - target_value)
	if distance <= jump_distance:
		value = target_value
