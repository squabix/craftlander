extends Entity3D

const ANIM_RUN = "run"
const ANIM_WALK = "walk"
const ANIM_IDLE = "idle"
const ANIM_ATTACK = "attack"

const RUN_THRESHOLD = 1.0

@export var animation_player: AnimationPlayer

func _process(delta: float) -> void:
	if Util.vec3to2(velocity, Util.VECTOR3Y).length() > RUN_THRESHOLD:
		animation_player.play("run")
	else:
		animation_player.play("idle")
