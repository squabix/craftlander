class_name Interactable3D
extends Area3D

@export var enabled := true
@export var channel := 0

@export_group("Tooltips", "tooltip")
@export var tooltip_enabled := ""
@export var tooltip_disabled := ""


func enable() -> void:
	enabled = true


func disable() -> void:
	enabled = false


func interact(_source: Node, _etc: Dictionary = { }) -> void:
	printerr("Interact")


func get_tooltip() -> String:
	return tooltip_enabled if enabled else tooltip_disabled
