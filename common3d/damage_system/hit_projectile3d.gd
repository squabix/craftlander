class_name HitProjectile3D
extends Hitbox3D

@export var launch_direction := Vector3.FORWARD
@export_custom(PROPERTY_HINT_NONE, "suffix:m/s") var speed := 14.0
@export_custom(PROPERTY_HINT_NONE, "suffix:m/s²") var gravity_scale := 2.0
@export_custom(PROPERTY_HINT_NONE, "suffix:1/s") var damping := 0.0
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var lifetime := 4.0
@export var free_on_collision := false

@export_group("Body Collision", "body_collision")
@export_range(0.0, 1.0) var body_collision_speed_multiplier := 1.0

var velocity: Vector3
var _time_alive := 0.0


func _ready() -> void:
	super()
	body_entered.connect(_on_body_entered)
	hit_node.connect(_on_hit_node)


func launch(inherited_velocity := Vector3.ZERO) -> void:
	velocity = global_transform.basis * (launch_direction.normalized() * speed) + inherited_velocity


func _physics_process(delta: float) -> void:
	velocity.y -= gravity_scale * delta
	if damping > 0.0:
		velocity *= exp(-damping * delta)
	global_position += velocity * delta
	if Util.vec3to2(velocity, Util.VECTOR3Y).length_squared() > 0.0001:
		look_at(global_position + velocity, Vector3.UP)

	_time_alive += delta
	if _time_alive >= lifetime:
		queue_free()


func _on_body_entered(body: Node3D) -> void:
	if free_on_collision:
		queue_free()
		return

	if body_collision_speed_multiplier < 1.0 and not is_source(body):
		velocity *= body_collision_speed_multiplier


func is_source(body: Node3D) -> bool:
	return is_instance_valid(damage) and is_instance_valid(damage.source) and body == damage.source


func _on_hit_node() -> void:
	if free_on_collision:
		queue_free()
