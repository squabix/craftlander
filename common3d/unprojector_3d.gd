class_name Unprojector3D
extends Marker3D

@export var target: CanvasItem

@export_group("Offsets")
@export_custom(PROPERTY_HINT_NONE, "suffix:px") var constant_offset := Vector2(0.0, 0.0)
@export var control_size_ratio_offset := Vector2(-0.5, -0.5)

@export_group("Distance Scaling")
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var reference_distance := 10.0
@export_range(0.0, 1.0) var scale_intensity := 1.0
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var max_scale := 1.0
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var min_scale := 0.25

var camera: Camera3D


func _ready() -> void:
	camera = get_viewport().get_camera_3d()


func _process(_delta: float) -> void:
	if not is_instance_valid(camera):
		printerr(name, " cannot unproject with invalid camera")
		set_process(false)
		return

	if not is_instance_valid(target):
		return

	# Hide target if behind camera
	if camera.is_position_behind(global_position):
		target.visible = false
		return
	
	target.visible = true
	
	# Scale the target node
	if scale_intensity > 0.0:
		target.scale = get_distance_scale()
	
	# Position the target on screen
	var screen_pos = camera.unproject_position(global_position)
	target.position = screen_pos + constant_offset
	
	if target is Control:
		target.position += target.size * target.scale * control_size_ratio_offset


func get_distance_scale() -> Vector2:
	var camera_distance := camera.global_position.distance_to(global_position)
	if camera_distance < 0.01: 
		camera_distance = 0.01
		
	var raw_projected_scale := reference_distance / camera_distance
	
	# Lerp between between flat scale (1.0) and perspective scale based on intensity, clamped to min/max limits
	return Vector2.ONE * clampf(lerpf(1.0, raw_projected_scale, scale_intensity), min_scale, max_scale)
