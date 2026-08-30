class_name PlayerMoveState
extends State

@export var stamina: Stamina

var move_mode: MoveMode


func enter() -> void:
	root.move_mode = move_mode
