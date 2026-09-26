class_name EndingHUD
extends CanvasLayer

const LINE_FADE_TIME := 0.8

@export var flash_rect: ColorRect
@export var line_label: Label
@export var credits: Credits


func flash(color: Color, hold := 0.15, fade := 0.7) -> void:
	color.a = 1.0
	flash_rect.color = color

	var tween := create_tween()
	tween.tween_interval(hold)
	tween.tween_property(flash_rect, ^"color:a", 0.0, fade)
	await tween.finished


func show_line(text: String, duration: float) -> void:
	line_label.text = text
	line_label.modulate.a = 0.0

	var tween := create_tween()
	tween.tween_property(line_label, ^"modulate:a", 1.0, LINE_FADE_TIME)
	tween.tween_interval(duration)
	tween.tween_property(line_label, ^"modulate:a", 0.0, LINE_FADE_TIME)
	await tween.finished


func play_credits() -> void:
	MouseModeController.show()
	credits.play()
	await credits.finished
