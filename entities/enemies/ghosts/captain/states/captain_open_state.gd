class_name CaptainOpenState
extends CaptainState

const ANIM_RECOVER := &"RecoverShot"

const CANNON_LOWER_TIME := 0.25
const POSE_TIME := 0.25
const OPEN_POSE_ROTATION := -0.3
const OPEN_POSE_SCALE := 0.92

const LIGHT_ENERGY_SCALE := 2.0
const STEAM_HEIGHT := 0.6
const STEAM_RADIUS := 0.7
const STEAM_FADE_TIME := 0.3

@export var next_state := &"Lull"
@export var color := Color(0.3, 0.9, 1.0)

var duration := 0.0


func run() -> void:
	begin_open()
	var steam := GhostVFX.aura(captain, captain.global_position + Vector3.UP * STEAM_HEIGHT, color, STEAM_RADIUS)

	var alive := await wait(duration * captain.recovery_scale())
	steam.fade_out(STEAM_FADE_TIME)
	end_open()
	if not alive:
		return

	settle()
	go_to(next_state)


func begin_open() -> void:
	captain.set_light(color, captain.read_aura_energy * LIGHT_ENERGY_SCALE)
	captain.health.hurt_multiplier = captain.read_open_damage_multiplier
	captain.unlock_facing()
	captain.cannon_aim.lower(CANNON_LOWER_TIME)
	captain.pose(OPEN_POSE_ROTATION, OPEN_POSE_SCALE, POSE_TIME)
	captain.play_animation(ANIM_RECOVER)


func end_open() -> void:
	captain.stop_animation(ANIM_RECOVER)
	captain.health.hurt_multiplier = 1.0


func settle() -> void:
	captain.pose(0.0, 1.0, POSE_TIME)
	captain.set_light(GhostCaptain.PHASE_COLORS[captain.phase], captain.read_aura_energy)
