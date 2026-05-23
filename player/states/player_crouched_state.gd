extends State

@onready var movement_mode := preload("res://player/states/player_crouched_movement_mode.tres")

@export var stamina: Stamina
@export var standing_collision: CollisionShape3D
@export var crouched_collision: CollisionShape3D

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
	elif Input.is_action_just_pressed("sprint") and stamina.is_usable():
		transition_to("Sprinting")
