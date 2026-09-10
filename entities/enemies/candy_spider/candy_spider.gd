extends Entity3D

@export var anim_tree: AnimationTree
@export var culling_controller: CullingController3D
@export var attack_ray: HitRay3D

func _ready() -> void:
	culling_controller.update_visibility_range()
	if attack_ray and attack_ray.damage:
		attack_ray.damage.source = self

func _process(_delta: float) -> void:
	# Interpolate between idle and walk by velocity
	var velocity_length := Util.vec3to2(velocity, Util.VECTOR3Y).length()
	if anim_tree:
		anim_tree.set(
			"parameters/MoveBlendSpace/blend_position",
			velocity_length / move_mode.max_speed.x
		)
