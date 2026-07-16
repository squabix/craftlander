class_name Hitbox3D
extends Area3D

signal hit_node

enum Mode { ENTERING, INSIDE, EXTERNAL }

@export var damage: Damage
@export var current_mode: Mode
@export var one_shot := false
@export var enabled := true
@export var auto_enable_wait_time: float

var hit_nodes: Array[Node]


func _ready() -> void:
	area_entered.connect(_hit_enter)
	if auto_enable_wait_time > 0.0:
		enabled = false
		await get_tree().create_timer(auto_enable_wait_time).timeout
		enabled = true


func _process(_delta: float) -> void:
	if current_mode == Mode.INSIDE:
		hit_overlap()


func enable() -> void:
	enabled = true


func disable() -> void:
	enabled = false


func hit_overlap() -> Array[Area3D]:
	var overlap := get_overlapping_areas()
	for area in overlap:
		hit(area)
	return overlap


static func get_knock_direction(y_rotation: float, knocking_damage: Damage) -> Vector3:
	var forward_direction := Vector3.FORWARD.rotated(Vector3.UP, y_rotation).normalized()
	if knocking_damage != null:
		return forward_direction.rotated(forward_direction.cross(Vector3.UP).normalized(), -deg_to_rad(knocking_damage.knockback_angle))
	return forward_direction


func hit(area: Area3D) -> bool:
	# BAIL if not enabled
	if not enabled:
		return false

	# ERROR if area does not exist
	if not is_instance_valid(area):
		printerr("%s cannot hit invalid area %s" % [self, area])
		return false

	# BAIL if area has already been hit & can only be hit once
	if area in hit_nodes and one_shot:
		return false

	# BAIL if area is not a hurtbox
	if not (area is Hurtbox3D):
		return false
	
	area.hurt(damage, get_knock_direction(global_rotation.y, damage))
	hit_nodes.append(area)
	hit_node.emit()

	return true


func _hit_enter(area: Area3D) -> bool:
	if current_mode == Mode.ENTERING:
		return hit(area)
	return false
