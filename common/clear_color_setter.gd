class_name ClearColorSetter
extends Node

@export var color: Color
@export var auto_set := true

func _ready() -> void:
	if auto_set:
		set_color()

func set_color() -> void:
	RenderingServer.set_default_clear_color(color)
