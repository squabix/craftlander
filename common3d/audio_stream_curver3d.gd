class_name AudioStreamCurver3D
extends AudioStreamPlayer

@export var position := Vector3.ZERO
@export_range(-80.0, 80.0, 0.001, "suffix:dB") var max_db := 3.0
@export_range(-80.0, 80.0, 0.001, "suffix:dB") var min_db := -80.0
@export_custom(PROPERTY_HINT_NONE, "suffix: m") var max_distance := 100.0

@export var attenuation_curve: Curve

var camera: Camera3D

func _ready() -> void:
	camera = get_viewport().get_camera_3d()

func _process(_delta: float) -> void:
	if not is_instance_valid(camera):
		camera = get_viewport().get_camera_3d()
		return
	
	var distance: float = position.distance_to(camera.global_position)
	var normalized_distance := clampf(distance / max_distance, 0.0, 1.0)
	var volume_factor := normalized_distance
	
	if attenuation_curve != null:
		volume_factor = attenuation_curve.sample(normalized_distance)
	
	# Scale between min_db and max_db based on the curve value
	volume_db = lerpf(min_db, max_db, volume_factor)
