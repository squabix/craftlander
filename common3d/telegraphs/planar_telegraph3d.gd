class_name PlanarTelegraph3D
extends Node3D

static var all: Array[PlanarTelegraph3D] = []

@export var material_override: StandardMaterial3D
@export var fill_start_scale_amount := 0.05

@export_group("Timing")
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var fill_duration := 0.4
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var activate_hold_time := 0.12
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var fade_time := 0.15

@export_group("Normal Conformity", "normal")
@export_range(0.0, 1.0) var normal_conformity := 0.5
@export_flags_3d_physics var normal_ground_mask := 1
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var normal_ray_distance := 2.0

@export_group("Color")
@export_color_no_alpha var color_base := Color(1.0, 0.3, 0.2)
@export_range(0.0, 1.0) var outline_alpha := 0.22
@export_range(0.0, 1.0) var fill_alpha := 0.5
@export var color_activate := Color(1.0, 1.0, 1.0, 0.9)

var yaw := 0.0
var is_activated := false
var fill: MeshInstance3D
var outline: MeshInstance3D


static func clear_all() -> void:
	for telegraph in all.duplicate():
		telegraph.queue_free()


static func _build_fan(arc: float, segments: int, start_angle: float) -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in segments:
		var a0 := start_angle + arc * i / segments
		var a1 := start_angle + arc * (i + 1) / segments
		tool.add_vertex(Vector3.ZERO)
		tool.add_vertex(Vector3(sin(a0), 0.0, -cos(a0)))
		tool.add_vertex(Vector3(sin(a1), 0.0, -cos(a1)))
	return tool.commit()


static func default_material() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.no_depth_test = true
	return material


func _ready() -> void:
	all.append(self)
	align_to_ground()
	_build()


func _exit_tree() -> void:
	all.erase(self)


func set_yaw(new_yaw: float) -> void:
	global_basis = global_basis.rotated(Vector3.UP, new_yaw - yaw)
	yaw = new_yaw


func activate() -> void:
	is_activated = true
	get_fill_material().albedo_color = color_activate
	fill.scale = Vector3.ONE
	get_tree().create_timer(activate_hold_time, false).timeout.connect(fade_out)


func dismiss() -> void:
	if is_activated:
		return
	is_activated = true
	if is_inside_tree():
		fade_out()
	else:
		queue_free()


func fade_out() -> void:
	var tween := create_tween()
	tween.tween_property(get_fill_material(), ^"albedo_color:a", 0.0, fade_time)
	tween.tween_callback(queue_free)


func add_layer(mesh: Mesh, alpha: float, start_scale: Vector3) -> MeshInstance3D:
	var layer := MeshInstance3D.new()
	layer.mesh = mesh
	layer.material_override = make_material(alpha)
	layer.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	layer.scale = start_scale
	add_child(layer)
	return layer


func get_fill_material() -> StandardMaterial3D:
	return fill.material_override as StandardMaterial3D


func make_material(alpha: float) -> StandardMaterial3D:
	var material := (
			default_material() if material_override == null
			else material_override.duplicate() as StandardMaterial3D
	)
	material.albedo_color = Color(color_base, alpha)
	return material


func align_to_ground() -> void:
	if normal_conformity <= 0.0:
		return

	var from := global_position + Vector3.UP * normal_ray_distance
	var query := PhysicsRayQueryParameters3D.create(from, global_position + Vector3.DOWN * normal_ray_distance * 2.0, normal_ground_mask)

	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return

	global_transform.basis = Util.align_basis_to_normal(global_transform.basis, hit.normal, normal_conformity)


func _build_mesh() -> Mesh:
	return null


func get_shape_scale() -> Vector3:
	return Vector3.ONE


func get_fill_scale_start() -> Vector3:
	return Vector3(fill_start_scale_amount, 1.0, fill_start_scale_amount)


func _build() -> void:
	scale = get_shape_scale()
	
	var mesh := _build_mesh()
	outline = add_layer(mesh, outline_alpha, Vector3.ONE)
	fill = add_layer(mesh, fill_alpha, get_fill_scale_start())

	var tween := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_property(fill, ^"scale", Vector3.ONE, fill_duration)
