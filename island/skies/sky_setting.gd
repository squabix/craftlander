class_name SkySetting
extends Resource

@export var time_index := 0
@export var sky_material: ShaderMaterial
#@export var ambient_energy := 0.5

@export_group("Sun", "sun")
@export_custom(PROPERTY_HINT_NONE, "suffix:°") var sun_rotation_degrees: Vector3
@export_color_no_alpha var sun_color := Color.WHITE
@export var sun_energy := 1.0


static func latest(...args: Array) -> SkySetting:
	if args.is_empty():
		return null
	var latest_setting: SkySetting = args.pop_front()
	for arg in args:
		if not arg is SkySetting:
			continue
		if arg.time_index <= latest_setting.time_index:
			continue
		latest_setting = arg
	return latest_setting


func update_sun(sun: DirectionalLight3D) -> void:
	sun.global_rotation_degrees = sun_rotation_degrees
	sun.light_energy = sun_energy
	sun.light_color = sun_color


func update_environment(world_environment: WorldEnvironment) -> void:
	world_environment.environment.sky.sky_material = sky_material
	#world_environment.environment.ambient_light_energy = ambient_energy
