extends Entity3D

const ANIM_RUN = "run"
const ANIM_WALK = "walk"
const ANIM_IDLE = "idle"
const ANIM_ATTACK = "attack"

const RUN_THRESHOLD = 0.5
const WALK_THESHOLD = 0.3

@export var anim_player: AnimationPlayer

func _process(_delta: float) -> void:
	var velocity_length := Util.vec3to2(velocity, Util.VECTOR3Y).length()
	if velocity_length > RUN_THRESHOLD:
		anim_player.play("run")
	#elif velocity_length > WALK_THESHOLD:
		#anim_player.play("walk")
	else:
		anim_player.play("idle")
