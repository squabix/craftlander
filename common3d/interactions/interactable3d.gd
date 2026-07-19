class_name Interactable3D
extends Area3D

@export var enabled := true
signal interacted_with(source: Node)
@export var channel := 0

@export_group("Tooltips", "tooltip")
@export var tooltip_enabled := ""
@export var tooltip_disabled := ""


func enable() -> void:
	enabled = true


func disable() -> void:
	enabled = false


func interact(source: Node, _etc: Dictionary = { }) -> void:
	interacted_with.emit(source)


func get_tooltip() -> String:
	return tooltip_enabled if enabled else tooltip_disabled
