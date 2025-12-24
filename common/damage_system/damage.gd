extends Resource
class_name Damage

@export var base_amount := 1.0
@export var variation := 0.0
@export var type: String

static func from_base(base: float) -> Damage:
	var damage := Damage.new()
	damage.base_amount = base
	return damage

func sample() -> float:
	return base_amount + randf_range(0.0, variation)
