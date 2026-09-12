class_name MeshFlashTrigger
extends SignalTrigger

@export var mesh_root: Node3D
@export var flash_color := Color.WHITE
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var flash_duration := 0.1

var flash_material: StandardMaterial3D

var _revert_tween: Tween
var _flashed_meshes: Array[Node] = []


func _ready() -> void:
	super()
	flash_material = StandardMaterial3D.new()
	flash_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	flash_material.albedo_color = flash_color


func trigger(..._args: Array) -> void:
	if disabled:
		return

	_flashed_meshes = Util.find_children_of_class(mesh_root, "MeshInstance3D")
	for mesh in _flashed_meshes:
		mesh.material_override = flash_material

	if is_instance_valid(_revert_tween):
		_revert_tween.kill()
	_revert_tween = create_tween()
	_revert_tween.tween_interval(flash_duration)
	_revert_tween.tween_callback(_revert)


func _revert() -> void:
	for mesh in _flashed_meshes:
		if not is_instance_valid(mesh):
			continue
		mesh.material_override = null
	_flashed_meshes.clear()
