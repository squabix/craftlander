class_name ControlTinter
extends Node

@export var tint_color: Color
@export var subtract: bool

var base_color: Color


func _ready() -> void:
	if _check_parent():
		base_color = get_parent().modulate


func _process(_delta: float) -> void:
	if !_check_parent():
		return

	var rect: Rect2 = get_parent().get_rect()
	var mouse: Vector2 = get_parent().get_global_mouse_position()
	if rect.has_point(mouse):
		tint()
	else:
		untint()


func tint() -> void:
	if subtract:
		get_parent().modulate = base_color - tint_color
	else:
		get_parent().modulate = base_color + tint_color


func untint() -> void:
	get_parent().modulate = base_color


func _check_parent() -> bool:
	if not get_parent() is Control:
		print_debug("ControlTinter will not work on ", get_parent().name, " because it is not a Control node")
		queue_free()
		return false
	return true
