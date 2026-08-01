class_name ProgressRadial
extends TextureRect

@export_range(0.0, 1.0) var value := 1.0:
	set(to):
		value = clampf(to, 0.0, 1.0)
		if is_material_valid():
			material.set_shader_parameter(&"fill_amount", value)

@export_group("Shader")
@export_file(".gdshader") var radial_shader := "res://common/ui/radial.gdshader"
@export var progress_property := &"fill_amount"


func _ready() -> void:
	value = value


func is_material_valid() -> bool:
	return (
			material is ShaderMaterial
			and ResourceLoader.exists(radial_shader)
			and material.shader == load(radial_shader)
	)
