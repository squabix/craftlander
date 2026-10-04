class_name Hurtbox3D
extends Area3D

signal was_hurt
signal was_dealt_damage(damage: Damage)
signal was_blocked(damage: Damage, direction: Vector3)
signal was_resisted(damage: Damage)

@export var health: Health
@export var inactive := false
@export var damage_multiplier := 1.0
@export var type_list: Array[StringName] = []
@export var type_acl: ACL
@export var free_parent_on_hurt := false
@export var size_multiplier := 1.0
@export var invulnerability_bypass_types: Array[StringName] = []

@export_group("Damage Override")
@export var damage_override: Damage
@export var override_null := false

@export_group("Knockback", "knockback")
@export var knockback_entity: Entity3D
@export var knockback_multiplier := Vector3.ONE
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var knockback_center_offset := Vector3.ZERO

@export_group("Auto Hurt", "auto_hurt")
@export var auto_hurt_damage: Damage
@export var auto_hurt_bodies_enabled := false
@export var auto_hurt_areas_enabled := false

var last_hurt_source: Node
var last_hurt_direction := Vector3.ZERO
var total_damage_taken := 0.0


func _ready() -> void:
	type_acl = ACL.resolve(type_acl, type_list)
	_scale_collision_shapes()
	_set_up_auto_hurt()


func _scale_collision_shapes() -> void:
	if is_equal_approx(size_multiplier, 1.0):
		return

	for child in get_children():
		if child is CollisionShape3D:
			child.scale *= size_multiplier


func auto_hurt(node: Node3D = null) -> void:
	var direction := get_hurt_direction_from(node.global_position) if is_instance_valid(node) else Vector3.ZERO
	hurt(auto_hurt_damage, direction)


func get_hurt_direction_from(from_position: Vector3) -> Vector3:
	return from_position.direction_to(global_position + knockback_center_offset)


func accepts_type(type: StringName) -> bool:
	return type_acl.passes(type)


func scale_damage(base_amount: float) -> float:
	return base_amount * damage_multiplier


func hurt(damage: Damage, direction: Vector3 = Vector3.ZERO) -> float:
	if inactive:
		return 0.0

	if damage_override != null and (damage != null or override_null):
		damage = damage_override.override(damage)
	
	# Confirm damage is valid
	if damage == null:
		return 0.0
	if not accepts_type(damage.type):
		return 0.0

	var dp := scale_damage(damage.sample())
	
	var success := not is_instance_valid(health) or health.hurt(dp, invulnerability_bypass_types.has(damage.type))
	if not success:
		if health.invulnerable:
			was_blocked.emit(damage, direction)
		elif dp < health.hurt_threshold:
			was_resisted.emit(damage)
		return 0.0
	
	total_damage_taken += dp
	knock(direction, damage.knockback_force)

	was_hurt.emit()
	was_dealt_damage.emit(damage)
	last_hurt_source = damage.source

	if free_parent_on_hurt:
		Util.safe_free(get_parent())

	return dp


func knock(direction: Vector3, base_force: float) -> void:
	if direction == Vector3.ZERO:
		return
	last_hurt_direction = direction
	if is_instance_valid(knockback_entity):
		knockback_entity.add_impulse(direction * base_force * knockback_multiplier)


func _set_up_auto_hurt() -> void:
	if auto_hurt_bodies_enabled:
		body_entered.connect(auto_hurt)
	if auto_hurt_areas_enabled:
		area_entered.connect(auto_hurt)
