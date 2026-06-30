class_name Damage
extends Resource

@export var base_amount := 1.0
@export var variation := 0.0
@export var force := 10.0
@export var type: String

var source: Node


static func from_base(base: float, damage_source: Node = null) -> Damage:
	var damage := Damage.new()
	damage.base_amount = base
	damage.source = damage_source
	return damage


func sample() -> float:
	return base_amount + randf_range(0.0, variation)
