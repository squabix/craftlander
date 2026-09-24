class_name NormalConformityRayCast3D
extends RayCast3D

@export var targets: Array[Node3D] = []
@export_range(0.0, 1.0) var conformity := 1.0
@export var default_rotation_degrees := Vector3.ZERO
@export var use_default_when_off_ground := true
@export var interpolation_speed := 8.0

var _rest_transforms: Dictionary[Node3D, Transform3D] = {}
var _current_basis := Basis.IDENTITY


func _ready() -> void:
	_current_basis = _get_default_basis()
	for target in targets:
		if is_instance_valid(target):
			_rest_transforms[target] = target.transform


func _physics_process(delta: float) -> void:
	var default_basis := _get_default_basis()
	var desired_basis := default_basis if use_default_when_off_ground else _current_basis

	if is_colliding():
		desired_basis = _get_aligned_basis(default_basis, get_collision_normal())

	_current_basis = _current_basis.slerp(desired_basis, clampf(interpolation_speed * delta, 0.0, 1.0))

	_apply_targets(_current_basis * default_basis.inverse())


func _get_default_basis() -> Basis:
	return Basis.from_euler(default_rotation_degrees * (PI / 180.0))


func _get_aligned_basis(base_basis: Basis, world_normal: Vector3) -> Basis:
	# Normal is sampled in world space but targets are tilted relative to this
	# node's parent, so it needs to be brought into that local frame first.
	var local_normal := (global_transform.basis.inverse() * world_normal).normalized()

	return Util.align_basis_to_normal(base_basis, local_normal, conformity)


func _apply_targets(delta_basis: Basis) -> void:
	for target in targets:
		if not is_instance_valid(target):
			continue

		var rest: Transform3D = _rest_transforms.get(target, target.transform)

		# Rotate around this node's position (the ground contact point) rather
		# than each target's own origin, so a target offset from that point
		# (e.g. Visuals sitting at chest height) swings into the slope instead
		# of just spinning in place and floating/clipping through the ground.
		var offset := rest.origin - position
		var new_basis := (delta_basis * rest.basis.orthonormalized()).orthonormalized().scaled(rest.basis.get_scale())

		target.transform = Transform3D(new_basis, position + delta_basis * offset)
