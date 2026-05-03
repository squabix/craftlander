extends Entity3D

const ANIM_RUN := "run"
const ANIM_WALK := "walk"
const ANIM_IDLE := "idle"
const ANIM_ATTACK := "attack"

const RUN_THRESHOLD := 0.5
const WALK_THESHOLD := 0.3

@export var anim_tree: AnimationTree

func _process(_delta: float) -> void:
	
	# Interpolate between animations by velocity
	var velocity_length := Util.vec3to2(velocity, Util.VECTOR3Y).length()
	if anim_tree:
		anim_tree.set(
			"parameters/RunBlendSpace/blend_position",
			velocity_length / movement_mode.max_speed.x
		)
