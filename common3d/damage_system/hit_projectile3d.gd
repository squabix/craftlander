class_name HitProjectile3D
extends Hitbox3D

@export var launch_direction := Vector3.FORWARD
@export_custom(PROPERTY_HINT_NONE, "suffix:m/s") var speed := 14.0
@export_custom(PROPERTY_HINT_NONE, "suffix:m/s²") var gravity_scale := 2.0
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var lifetime := 4.0

var velocity: Vector3
var _time_alive := 0.0


func _ready() -> void:
	super()
	body_entered.connect(_on_body_entered)
	hit_node.connect(_on_hit_node)


func launch() -> void:
	velocity = global_transform.basis * (launch_direction.normalized() * speed)


func _physics_process(delta: float) -> void:
	velocity.y -= gravity_scale * delta
	global_position += velocity * delta
	if velocity.length_squared() > 0.0001:
		look_at(global_position + velocity, Vector3.UP)

	_time_alive += delta
	if _time_alive >= lifetime:
		queue_free()


func _on_body_entered(_body: Node3D) -> void:
	queue_free()


func _on_hit_node() -> void:
	queue_free()
