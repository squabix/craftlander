class_name AdvancedCamera3D
extends Camera3D

@export var zoom_amount: float = 1.0
@export_range(0.0, 1.0) var zoom_speed: float = 1.0

var base_fov: float


func _ready() -> void:
	base_fov = GameSettings.config.get_value("gameplay", "fov", fov)


func _process(delta: float) -> void:
	fov = lerp(fov, base_fov / zoom_amount, zoom_speed)
