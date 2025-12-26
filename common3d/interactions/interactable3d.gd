extends Area3D
class_name Interactable3D

@export var enabled := true
@export var id := 0
@export var enabled_tooltip := ""
@export var disabled_tooltip := ""

func enable() -> void:
	enabled = true

func disable() -> void:
	enabled = false

func interact(_source: Node, _etc: Dictionary={}) -> void:
	printerr("Interact")

func get_tooltip() -> String:
	return enabled_tooltip if enabled else disabled_tooltip
