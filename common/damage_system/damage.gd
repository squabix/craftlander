extends Resource
class_name Damage

@export var base_amount := 1.0
@export var variation := 0.0

func sample() -> float:
	return base_amount + randf_range(0.0, variation)
