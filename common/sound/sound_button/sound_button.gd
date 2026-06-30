class_name SoundButton
extends Button

@export var streams: ButtonStreams


func _ready() -> void:
	button_down.connect(play_press)
	button_up.connect(play_release)
	mouse_entered.connect(play_hover)


func play_press() -> void:
	if streams.press_stream:
		SoundManager.play(streams.press_stream)


func play_release() -> void:
	if streams.release_stream:
		SoundManager.play(streams.release_stream)


func play_hover() -> void:
	if streams.hover_stream:
		SoundManager.play(streams.hover_stream)
