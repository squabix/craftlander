class_name PlayerWalkingState
extends PlayerMoveState

func _ready() -> void:
	move_mode = preload("res://player/states/player_walking_move_mode.tres")

func update(_delta: float) -> void:
	if Input.is_action_just_pressed(&"sprint") and stamina.is_usable():
		transition_to(&"Sprinting")
