class_name CollectedItemEntry
extends PanelContainer

signal expired

const HOLD_DURATION := 5.0 # s
const FADE_DURATION := 0.4 # s
const LABEL_FORMAT := "Collected %s"

@export var icon_rect: TextureRect
@export var label: Label

var _hold_timer: SceneTreeTimer


func setup(item: Item) -> void:
	if is_instance_valid(icon_rect):
		icon_rect.texture = item.icon
	if is_instance_valid(label):
		label.text = LABEL_FORMAT % item.name

	_hold_timer = get_tree().create_timer(HOLD_DURATION)
	_hold_timer.timeout.connect(_fade_out)


func expire_now() -> void:
	if is_instance_valid(_hold_timer) and _hold_timer.timeout.is_connected(_fade_out):
		_hold_timer.timeout.disconnect(_fade_out)
	_fade_out()


func _fade_out() -> void:
	var fade_tween := create_tween()
	fade_tween.tween_property(self, ^"modulate:a", 0.0, FADE_DURATION)
	fade_tween.finished.connect(_finish)


func _finish() -> void:
	expired.emit()
	queue_free()
