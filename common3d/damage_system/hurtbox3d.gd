extends Area3D
class_name Hurtbox3D

signal was_hurt
signal was_dealt_damage(amount: float)

@export var health: Health
@export var inactive := false
@export var free_parent_on_hurt := false
@export var damage_multiplier := 1.0
@export var center := Vector3.ZERO

@export_group("Auto Hurt")
@export var bodies_auto_hurt := false
@export var areas_auto_hurt := false
@export var auto_hurt_damage := 1.0

var last_hurt_direction: Vector3
var total_damage_taken: float

func _ready() -> void:
	_set_up_auto_hurt()

func auto_hurt(node: Node3D=null) -> void:
	hurt(auto_hurt_damage, node.global_position)

func _set_up_auto_hurt() -> void:
	if bodies_auto_hurt:
		body_entered.connect(auto_hurt)
	if areas_auto_hurt:
		area_entered.connect(auto_hurt)

func get_hurt_direction_from(from_position: Vector3) -> Vector3:
	return from_position.direction_to(global_position + center)

func hurt(damage: float, direction: Vector3=Vector3.ZERO) -> float:
	if inactive:
		return 0.0
	
	damage *= damage_multiplier
	total_damage_taken += damage
	
	if is_instance_valid(health):
		health.hurt(damage)
	
	if direction != Vector3.ZERO:
		last_hurt_direction = direction
	was_hurt.emit()
	was_dealt_damage.emit(damage)
	
	if free_parent_on_hurt:
		get_parent().queue_free()
	
	return damage
