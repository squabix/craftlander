class_name SkyPalette
extends Resource

@export var sky_material: ShaderMaterial

@export_group("Sun", "sun")
@export var sun_color: Gradient
@export var sun_energy: Curve

@export_group("Adjustments")
@export var brightness: Curve
@export var contrast: Curve
@export var saturation: Curve


func update_sun(sun: DirectionalLight3D, normalized_time_of_day: float) -> void:
	sun.light_color = sun_color.sample(normalized_time_of_day)
	sun.light_energy = sun_energy.sample(normalized_time_of_day)


func update_environment(world_environment: WorldEnvironment, normalized_time_of_day: float) -> void:
	var environment := world_environment.environment
	environment.sky.sky_material = sky_material
	
	# Adjustments
	if brightness != null:
		environment.adjustment_brightness = brightness.sample(normalized_time_of_day)
	if contrast != null:
		environment.adjustment_contrast = contrast.sample(normalized_time_of_day)
	if saturation != null:
		environment.adjustment_saturation = saturation.sample(normalized_time_of_day)
	
