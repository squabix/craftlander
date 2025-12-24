extends RayCast3D
class_name HitRay3D

signal hit_node

@export var damage: Damage
@export var one_shot := false

var hit_nodes: Array[Node]

func enable() -> void:
	enabled = true

func disable() -> void:
	enabled = false

func _ready() -> void:
	collide_with_areas = true
	collide_with_bodies = false
	if damage == null:
		printerr(name, " has no damage")

func hit() -> bool:
	var area := get_collider() as Area3D
	
	# ERROR if area does not exist
	if not is_instance_valid(area):
		return false
	
	# BAIL if area is not a hurtbox
	if not (area is Hurtbox3D):
		return false
	
	# BAIL if area has already been hit & can only be hit once
	if area in hit_nodes and one_shot:
		return false
	
	area.hurt(damage, Vector3.FORWARD.rotated(Util.VECTOR3Y, global_rotation.y))
	hit_nodes.append(area)
	hit_node.emit()
	
	return true
