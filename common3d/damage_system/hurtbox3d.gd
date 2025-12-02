extends Area3D
class_name Hurtbox3D

signal was_hurt
signal was_dealt_damage(amount: float)

@export var health: Health
@export var inactive := false
@export var free_parent_on_hurt := false
@export var damage_multiplier := 1.0

@export_group("Auto Hurt")
@export var bodies_auto_hurt := false
@export var areas_auto_hurt := false
@export var auto_hurt_damage := 1.0

func _ready() -> void:
	_set_up_auto_hurt()

func auto_hurt(_node: Node=null) -> void:
	hurt(auto_hurt_damage)

func _set_up_auto_hurt() -> void:
	if bodies_auto_hurt:
		body_entered.connect(auto_hurt)
	if areas_auto_hurt:
		area_entered.connect(auto_hurt)

func hurt(damage: float) -> float:
	if inactive:
		return 0.0
	
	damage *= damage_multiplier
	
	if is_instance_valid(health):
		health.hurt(damage)
	was_hurt.emit()
	was_dealt_damage.emit(damage)
	
	if free_parent_on_hurt:
		get_parent().queue_free()
	
	return damage
