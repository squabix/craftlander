extends Resource
class_name Damage

@export var base_amount: float
@export var variation: float

func sample() -> float:
	return base_amount + randf_range(0.0, variation)
