extends Entity3D

@export var anim_tree: AnimationTree
@export var culling_controller: CullingController3D

func _ready() -> void:
	culling_controller.update_visibility_range()

func _process(_delta: float) -> void:
	# Interpolate between idle and walk by velocity
	var velocity_length := Util.vec3to2(velocity, Util.VECTOR3Y).length()
	if anim_tree:
		anim_tree.set(
			"parameters/MoveBlendSpace/blend_position",
			velocity_length / move_mode.max_speed.x
		)
