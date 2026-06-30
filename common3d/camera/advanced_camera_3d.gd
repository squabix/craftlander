class_name AdvancedCamera3D
extends Camera3D

@export var zoom_amount: float = 1.0
@export_range(0.0, 1.0) var zoom_speed: float = 1.0

@onready var base_fov: float = fov


func _process(delta: float) -> void:
	fov = lerp(fov, base_fov / zoom_amount, zoom_speed)
