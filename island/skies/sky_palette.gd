class_name SkyPalette
extends Resource

const DEFAULT_MOON_DIRECTION := Vector3(0.35, 0.45, -0.82)

@export var sky_material: ShaderMaterial

@export_group("Sun", "sun")
@export var sun_color: Gradient
@export var sun_energy: Curve

@export_group("Moon", "moon")
@export var moon_color := Color(0.75, 0.85, 1.0)
@export var moon_energy := 0.4
@export_range(1.0, 10.0) var moon_fade_sharpness := 4.0

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


func update_moon(moon: DirectionalLight3D, normalized_time_of_day: float) -> void:
	var sun_elevation := sin(normalized_time_of_day * TAU)
	var night_amount := clampf(-sun_elevation * moon_fade_sharpness, 0.0, 1.0)

	moon.light_color = moon_color
	moon.light_energy = moon_energy * night_amount
	moon.visible = moon.light_energy > 0.0
	moon.global_transform.basis = Basis.looking_at(-_get_moon_direction(), Vector3.UP)


func update_environment(world_environment: WorldEnvironment, normalized_time_of_day: float) -> void:
	var environment := world_environment.environment
	if environment.sky.sky_material != sky_material:
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


func _get_moon_direction() -> Vector3:
	var direction: Variant = sky_material.get_shader_parameter("moon_direction") if sky_material != null else null
	if direction is Vector3 and direction != Vector3.ZERO:
		return (direction as Vector3).normalized()
	return DEFAULT_MOON_DIRECTION.normalized()
