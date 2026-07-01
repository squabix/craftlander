class_name SinWaver
extends Node

@export_custom(PROPERTY_HINT_NONE, "suffix:s") var period: float = 5.0
@export var strength: float = 10.0
@export var random: bool = true

var randomness: float = 0.0
var time: float


func _init() -> void:
	if random:
		randomness = -float(randi())


func _process(delta: float) -> void:
	time += delta


func time_sample() -> float:
	return sample(randomness + time)


func sample(x: float) -> float:
	return sin(x * period) * strength


func get_minimum() -> float:
	return -strength


func get_maximum() -> float:
	return strength
