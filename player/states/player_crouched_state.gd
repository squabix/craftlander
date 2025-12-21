extends State

@onready var movement_mode := preload("res://player/states/player_crouched_movement_mode.tres")

@onready var standing_collision: CollisionShape3D = %StandingCollisionShape
@onready var crouched_collision: CollisionShape3D = %CrouchedCollisionShape

func enter() -> void:
	root.movement_mode = movement_mode
	standing_collision.disabled = true
	crouched_collision.disabled = false

func exit() -> void:
	standing_collision.disabled = false
	crouched_collision.disabled = true

func update(_delta: float) -> void:
	if Input.is_action_just_pressed("crouch") or Input.is_action_just_pressed("jump"):
		transition_to("Walking")
	elif Input.is_action_just_pressed("sprint"):
		transition_to("Sprinting")
