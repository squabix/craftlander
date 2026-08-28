class_name HealthBar
extends InterpolatedBar

const CURRENT: String = "CURRENT"
const MAX: String = "MAX"

@export var health: Health
@export var instant_on_max_hp_change := false

@export_group("Label")
@export var label: Label
@export var label_format: String = "%s / %s"
@export var rounding_places: int = 1


func _process(_delta: float) -> void:
	if not is_instance_valid(health):
		return

	var max_hp_changed := not is_equal_approx(health.max_hp, max_value)
	max_value = health.max_hp

	if instant_on_max_hp_change and max_hp_changed:
		if _value_tween and _value_tween.is_valid():
			_value_tween.kill()
		value = health.hp
	target_value = health.hp

	if is_instance_valid(label):
		label.text = get_label_text()


func get_label_text() -> String:
	return label_format.replace(CURRENT, get_hp_str()).replace(MAX, get_max_hp_str())


func get_hp_str() -> String:
	return str(Util.round_places(health.hp, rounding_places))


func get_max_hp_str() -> String:
	return str(Util.round_places(health.max_hp, rounding_places))
