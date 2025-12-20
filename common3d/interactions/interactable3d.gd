extends Area3D
class_name Interactable3D

@export var enabled := true
@export var id := 0

func enable() -> void:
	enabled = true

func disable() -> void:
	enabled = false

func interact(_root: Node, _etc: Dictionary={}) -> void:
	printerr("Interact")
