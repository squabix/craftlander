extends Node
class_name CollisionCycler3D

signal enabled(shape: CollisionShape3D)
signal disabled(shape: CollisionShape3D)

@export var collision_shapes: Array[CollisionShape3D]

func cycle(enabled_shapes: Array) -> void:
	for shape in collision_shapes:
		if shape in enabled_shapes:
			shape.disabled = false
			enabled.emit(shape)
		else:
			shape.disabled = true
			disabled.emit(shape)
