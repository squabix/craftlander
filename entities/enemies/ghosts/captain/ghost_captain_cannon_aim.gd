class_name GhostCaptainCannonAim
extends SkeletonModifier3D

const PASSES := 4

@export var arm_bone := &"LeftShoulder"
@export var hand_bone := &"LeftHand"

var aim_point := Vector3.ZERO

var _blend_tween: Tween


func _process_modification() -> void:
	var skeleton := get_skeleton()
	if skeleton == null:
		return
	
	var arm := skeleton.find_bone(arm_bone)
	var hand := skeleton.find_bone(hand_bone)
	if arm < 0 or hand < 0:
		return

	var arm_pose := skeleton.get_bone_global_pose(arm)
	var hand_pose := skeleton.get_bone_global_pose(hand)
	var target := skeleton.global_transform.affine_inverse() * aim_point
	var hand_direction := hand_pose.basis.y.normalized()
	var hand_position := hand_pose.origin

	var total := Quaternion.IDENTITY
	for _pass in PASSES:
		var wanted := (target - hand_position).normalized()
		if wanted.is_zero_approx() or hand_direction.dot(wanted) < -0.999:
			return
		
		var step := Quaternion(hand_direction, wanted)
		total = step * total
		hand_direction = step * hand_direction
		hand_position = arm_pose.origin + step * (hand_position - arm_pose.origin)

	arm_pose.basis = Basis(total) * arm_pose.basis
	skeleton.set_bone_global_pose(arm, arm_pose)


func raise(duration: float) -> void:
	blend(1.0, duration)


func lower(duration: float) -> void:
	blend(0.0, duration)


func blend(to_influence: float, duration: float) -> void:
	if _blend_tween != null:
		_blend_tween.kill()
	_blend_tween = create_tween()
	_blend_tween.tween_property(self, ^"influence", to_influence, duration)


func get_aim_direction() -> Vector3:
	var skeleton := get_skeleton()
	if skeleton == null:
		return Vector3.ZERO
	
	var hand := skeleton.find_bone(hand_bone)
	if hand < 0:
		return Vector3.ZERO
	
	var hand_position := skeleton.global_transform * skeleton.get_bone_global_pose(hand).origin
	return (aim_point - hand_position).normalized()
