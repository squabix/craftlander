class_name Damage
extends Resource

@export_custom(PROPERTY_HINT_NONE, "suffix:dp") var base_amount := 1.0
@export_custom(PROPERTY_HINT_NONE, "suffix:dp") var variation := 0.0
@export var type: StringName

@export_group("Knockback", "knockback")
@export var knockback_force := 10.0
@export_custom(PROPERTY_HINT_NONE, "suffix:°") var knockback_angle := 0.0

var source: Node


static func from_base(base: float, damage_source: Node = null) -> Damage:
	var damage := Damage.new()
	damage.base_amount = base
	damage.source = damage_source
	return damage


func sample() -> float:
	return base_amount + randf_range(0.0, variation)

func override(other_damage: Damage) -> Damage:
	if other_damage == null:
		return duplicate()
	
	var overrided_damage: Damage = duplicate()
	overrided_damage.type = other_damage.type
	overrided_damage.source = other_damage.source
	return overrided_damage
