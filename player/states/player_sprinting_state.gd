class_name PlayerSprintingState
extends PlayerMoveState

const MIN_FORWARD_MOTION: float = 0.7
const STAMINA_COST := 0.25

@export var camera: Camera3D

@export_group("FOV", "fov")
@export_custom(PROPERTY_HINT_NONE, "suffix:°") var fov_boost := 10.0
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var fov_transition_time := 0.3

var _scene_fov := 0.0
var _fov_tween: Tween


func _ready() -> void:
	move_mode = preload("res://player/states/player_sprinting_move_mode.tres")
	_scene_fov = camera.fov


func enter() -> void:
	super()
	tween_fov(get_base_fov() + fov_boost)


func exit() -> void:
	tween_fov(get_base_fov())


func is_walking_forward() -> bool:
	return root.last_motion_direction.z <= -MIN_FORWARD_MOTION


func physics_update(_delta: float) -> void:
	stamina.spend(STAMINA_COST)


func update(_delta: float) -> void:
	if not (stamina.is_usable() and is_walking_forward()):
		transition_to(&"Walking")


func get_base_fov() -> float:
	return GameSettings.config.get_value("gameplay", "fov", _scene_fov)


func tween_fov(to: float) -> void:
	if _fov_tween != null:
		_fov_tween.kill()

	_fov_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_fov_tween.tween_property(camera, ^"fov", to, fov_transition_time)
