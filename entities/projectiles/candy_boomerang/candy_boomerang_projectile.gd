class_name CandyBoomerangProjectile
extends HitProjectile3D

signal returned

@export_custom(PROPERTY_HINT_NONE, "suffix:m") var outbound_distance := 7.0
@export_custom(PROPERTY_HINT_NONE, "suffix:m/s") var return_speed := 20.0
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var catch_radius := 1.0

var thrower: Node3D
var is_returning := false

var _spawn_position: Vector3


func _ready() -> void:
	super()
	_spawn_position = global_position


func launch(inherited_velocity := Vector3.ZERO) -> void:
	super(inherited_velocity)
	gravity_scale = 0.0
	thrower = damage.source as Node3D


func _physics_process(delta: float) -> void:
	if is_returning:
		return_to_thrower(delta)
	else:
		fly_outbound(delta)

	_time_alive += delta
	if _time_alive >= lifetime:
		is_returning = true


func fly_outbound(delta: float) -> void:
	global_position += velocity * delta
	look_at(global_position + velocity, Vector3.UP)

	if global_position.distance_to(_spawn_position) >= outbound_distance:
		is_returning = true


func return_to_thrower(delta: float) -> void:
	if not is_instance_valid(thrower):
		returned.emit()
		queue_free()
		return

	var offset := thrower.global_position - global_position
	if offset.length() <= catch_radius:
		returned.emit()
		queue_free()
		return

	velocity = offset.normalized() * return_speed
	global_position += velocity * delta
	look_at(global_position + velocity, Vector3.UP)
