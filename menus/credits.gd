class_name Credits
extends Control

signal finished

const START_FRACTION := 1.0

@export var content: Control
@export_custom(PROPERTY_HINT_NONE, "suffix:px/s") var scroll_speed := 30.0

@export_group("Speeding Up", "speed_up")
@export var speed_up_multiplier := 4.0
@export var speed_up_action := &"ui_accept"

var playing := false


func _ready() -> void:
	hide()
	set_process(false)


func _process(delta: float) -> void:
	if not playing:
		return

	content.position.y -= get_speed() * delta
	if content.position.y + content.size.y < 0.0:
		finish()


func get_speed() -> float:
	var speed := scroll_speed
	if Input.is_action_pressed(speed_up_action):
		speed *= speed_up_multiplier
	return speed


func play() -> void:
	content.modulate.a = 0.0
	show()
	await get_tree().process_frame
	content.size.y = content.get_combined_minimum_size().y
	content.position.y = size.y * START_FRACTION
	content.modulate.a = 1.0
	playing = true
	set_process(true)


func finish() -> void:
	playing = false
	set_process(false)
	hide()
	finished.emit()
