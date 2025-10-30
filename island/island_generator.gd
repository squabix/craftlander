extends Node3D


@export var mesh_instance: MeshInstance3D
@export var collision_shape: CollisionShape3D

func _ready() -> void:
	collision_shape.shape = HeightMapShape3D.new()
	
