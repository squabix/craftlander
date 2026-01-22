extends Entity3D

const ANIM_RUN = "run"
const ANIM_WALK = "walk"
const ANIM_IDLE = "idle"
const ANIM_ATTACK = "attack"

const RUN_THRESHOLD = 2.5
const WALK_THESHOLD = 0.3

@export var animation_player: AnimationPlayer

func _process(_delta: float) -> void:
	var velocity_length := Util.vec3to2(velocity, Util.VECTOR3Y).length()
	if velocity_length > RUN_THRESHOLD:
		animation_player.play("run")
	elif velocity_length > WALK_THESHOLD:
		animation_player.play("walk")
	else:
		animation_player.play("idle")
