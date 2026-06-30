class_name ThirdPersonCameraSpring
extends Node3D

@export var arm: RayCast3D
@export var arm_collision_margin: float = 0.1
@export var camera: Node3D

@export_category("Zoom")
@export var zoom_enabled: bool
@export var min_zoom_amount: float = 5.0
@export var max_zoom_amount: float = 20.0
@export var zoom_in_action: StringName
@export var zoom_out_action: StringName
@export var zoom_speed: float = 0.2
@export_range(0.0, 1.0) var zoom_lerp_weight: float = 1.0

@export_category("Rotation")
@export var mouse_sensitivity: float = 0.05
@export_range(0.0, 1.0) var rotate_lerp_weight: float = 1.0
@export var rotate_action: StringName

var zoom_amount: float
var target_zoom_amount: float
var target_rotation_degrees: Vector3


func _ready() -> void:
	zoom_amount = arm.target_position.length()
	target_zoom_amount = arm.target_position.length()
	target_rotation_degrees = global_rotation_degrees


func _process(delta: float) -> void:
	zoom_amount = lerp(zoom_amount, target_zoom_amount, zoom_lerp_weight)
	rotation_degrees = rotation_degrees.lerp(target_rotation_degrees, rotate_lerp_weight)
	arm.target_position = Vector3.BACK * zoom_amount
	arm.force_raycast_update()

	if arm.is_colliding():
		camera.global_position = arm.get_collision_point().move_toward(global_position, arm_collision_margin)
	else:
		camera.global_position = arm.to_global(arm.target_position)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed(zoom_in_action):
		zoom(-1.0)
	if event.is_action_pressed(zoom_out_action):
		zoom(1.0)
	if event is InputEventMouseMotion:
		if not rotate_action.is_empty() and not Input.is_action_pressed(rotate_action):
			return
		turn_head(event.relative * mouse_sensitivity)


func zoom(direction: float) -> void:
	target_zoom_amount = clamp(target_zoom_amount + zoom_speed * direction, min_zoom_amount, max_zoom_amount)


func turn_head(relative: Vector2) -> void:
	target_rotation_degrees.x -= relative.y
	target_rotation_degrees.y -= relative.x
