class_name CaptainMeleeState
extends CaptainAttackState

@export var cutlass_holder: ItemHolder3D


func get_cutlass_damage(multiplier := 1.0) -> Damage:
	var cutlass := cutlass_holder.get_held_item() as HarvestingTool
	var damage: Damage = cutlass.damage.duplicate()
	damage.base_amount *= multiplier
	damage.knockback_force *= multiplier
	damage.source = captain
	return damage
