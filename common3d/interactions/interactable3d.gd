extends Area3D
class_name Interactable3D

@export var enabled: bool = true
@export var id: int

func enable() -> void:
	enabled = true

func disable() -> void:
	enabled = false

func interact(_root: Node, _etc: Dictionary={}) -> void:
	print("Interact")
