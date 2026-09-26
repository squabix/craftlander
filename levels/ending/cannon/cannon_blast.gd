class_name CannonBlast
extends Hitbox3D

@export_custom(PROPERTY_HINT_NONE, "suffix:s") var lifetime := 0.25
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var linger_time := 1.5


func _ready() -> void:
	super()
	await get_tree().create_timer(lifetime).timeout
	disable()
	await get_tree().create_timer(linger_time).timeout
	queue_free()


func hit(area: Area3D) -> bool:
	if not area.get_parent() is Player:
		return false
	var offset := area.global_position - global_position
	global_rotation.y = atan2(-offset.x, -offset.z)
	return super(area)
