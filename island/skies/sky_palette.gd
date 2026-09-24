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

@export_group("Fog", "fog")
@export var fog_color := Color(0.5, 0.5, 0.55)
@export_custom(PROPERTY_HINT_NONE, "suffix:1/m") var fog_density := 0.0
@export_range(0.0, 1.0) var fog_sky_affect := 0.0


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
	
	# Fog
	environment.fog_enabled = fog_density > 0.0
	environment.fog_sky_affect = fog_sky_affect
	if fog_density > 0.0:
		environment.fog_light_color = fog_color
		environment.fog_density = fog_density
